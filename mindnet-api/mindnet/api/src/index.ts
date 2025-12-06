import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Ensure uploads directory exists
if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads');
}

// Multer config for audio uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${Math.random().toString(36).substring(7)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});
const upload = multer({ 
  storage,
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['audio/webm', 'audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/ogg'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only audio files allowed.'));
    }
  }
});

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Middleware: verify JWT
const authenticate = async (req: any, res: any, next: any) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    const decoded: any = jwt.verify(token, JWT_SECRET);
    const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
    if (!user) return res.status(401).json({ error: 'User not found' });
    req.user = user;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// ============= AUTH =============

// Register
app.post('/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const exists = await prisma.user.findFirst({ where: { email } });
    if (exists) return res.status(400).json({ error: 'Email already registered' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { 
        name: name || email.split('@')[0],
        email,
        password: hashedPassword,
        slots_free: 7, 
        slots_total: 7 
      }
    });

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Login
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findFirst({ where: { email } });
    if (!user || !user.password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get current user
app.get('/auth/me', authenticate, (req: any, res) => {
  const { password, ...user } = req.user;
  res.json(user);
});

// ============= CONTACTS =============

// Get all contacts
app.get('/contacts', authenticate, async (req: any, res) => {
  try {
    const contacts = await prisma.contact.findMany({
      where: { owner_id: req.user.id },
      orderBy: { created_at: 'desc' }
    });
    res.json(contacts);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get contact by ID
app.get('/contacts/:id', authenticate, async (req: any, res) => {
  try {
    const contact = await prisma.contact.findFirst({
      where: { id: req.params.id, owner_id: req.user.id }
    });
    if (!contact) return res.status(404).json({ error: 'Contact not found' });
    res.json(contact);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Create contact
app.post('/contacts', authenticate, async (req: any, res) => {
  try {
    const { name, birthday, note, telegram } = req.body;
    if (!name) return res.status(400).json({ error: 'Name required' });

    // Check if user has free slots
    if (req.user.slots_free <= 0) {
      return res.status(403).json({ error: 'No free slots. Purchase more slots.' });
    }

    const contact = await prisma.contact.create({
      data: {
        owner_id: req.user.id,
        name,
        birthday: birthday ? new Date(birthday) : null,
        note,
        telegram
      }
    });

    // Decrease free slots
    await prisma.user.update({
      where: { id: req.user.id },
      data: { slots_free: { decrement: 1 } }
    });

    res.json(contact);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Update contact
app.put('/contacts/:id', authenticate, async (req: any, res) => {
  try {
    const { name, birthday, note, telegram, last_interaction } = req.body;
    const contact = await prisma.contact.findFirst({
      where: { id: req.params.id, owner_id: req.user.id }
    });
    if (!contact) return res.status(404).json({ error: 'Contact not found' });

    const updated = await prisma.contact.update({
      where: { id: req.params.id },
      data: {
        name: name || contact.name,
        birthday: birthday ? new Date(birthday) : contact.birthday,
        note: note !== undefined ? note : contact.note,
        telegram: telegram !== undefined ? telegram : contact.telegram,
        last_interaction: last_interaction ? new Date(last_interaction) : contact.last_interaction
      }
    });
    res.json(updated);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete contact
app.delete('/contacts/:id', authenticate, async (req: any, res) => {
  try {
    const contact = await prisma.contact.findFirst({
      where: { id: req.params.id, owner_id: req.user.id }
    });
    if (!contact) return res.status(404).json({ error: 'Contact not found' });

    await prisma.contact.delete({ where: { id: req.params.id } });
    
    // Return slot back
    await prisma.user.update({
      where: { id: req.user.id },
      data: { slots_free: { increment: 1 } }
    });

    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get contacts with upcoming birthdays (next 30 days)
app.get('/contacts/reminders/birthdays', authenticate, async (req: any, res) => {
  try {
    const contacts = await prisma.contact.findMany({
      where: { owner_id: req.user.id, birthday: { not: null } }
    });

    const now = new Date();
    const upcoming = contacts.filter(c => {
      if (!c.birthday) return false;
      const bd = new Date(c.birthday);
      const thisYearBirthday = new Date(now.getFullYear(), bd.getMonth(), bd.getDate());
      const daysUntil = Math.ceil((thisYearBirthday.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      return daysUntil >= 0 && daysUntil <= 30;
    });

    res.json(upcoming);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get contacts not contacted in >30 days
app.get('/contacts/reminders/inactive', authenticate, async (req: any, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const contacts = await prisma.contact.findMany({
      where: {
        owner_id: req.user.id,
        OR: [
          { last_interaction: { lt: thirtyDaysAgo } },
          { last_interaction: null }
        ]
      },
      orderBy: { last_interaction: 'asc' }
    });

    res.json(contacts);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ============= IDEAS =============

// Get all ideas
app.get('/ideas', authenticate, async (req: any, res) => {
  try {
    const ideas = await prisma.idea.findMany({
      where: { owner_id: req.user.id },
      orderBy: { updated_at: 'desc' },
      include: {
        _count: { select: { commits: true } }
      }
    });
    res.json(ideas);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get idea by ID
app.get('/ideas/:id', authenticate, async (req: any, res) => {
  try {
    const idea = await prisma.idea.findFirst({
      where: { id: req.params.id, owner_id: req.user.id },
      include: {
        commits: {
          orderBy: { created_at: 'asc' }
        }
      }
    });
    if (!idea) return res.status(404).json({ error: 'Idea not found' });
    res.json(idea);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Create idea
app.post('/ideas', authenticate, async (req: any, res) => {
  try {
    const { title, summary, fork_from } = req.body;
    if (!title) return res.status(400).json({ error: 'Title required' });

    const idea = await prisma.idea.create({
      data: {
        owner_id: req.user.id,
        title,
        summary,
        fork_from
      }
    });
    res.json(idea);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Update idea
app.put('/ideas/:id', authenticate, async (req: any, res) => {
  try {
    const { title, summary } = req.body;
    const idea = await prisma.idea.findFirst({
      where: { id: req.params.id, owner_id: req.user.id }
    });
    if (!idea) return res.status(404).json({ error: 'Idea not found' });

    const updated = await prisma.idea.update({
      where: { id: req.params.id },
      data: { title, summary }
    });
    res.json(updated);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete idea
app.delete('/ideas/:id', authenticate, async (req: any, res) => {
  try {
    const idea = await prisma.idea.findFirst({
      where: { id: req.params.id, owner_id: req.user.id }
    });
    if (!idea) return res.status(404).json({ error: 'Idea not found' });

    // Delete all commits first
    await prisma.commit.deleteMany({ where: { idea_id: req.params.id } });
    await prisma.idea.delete({ where: { id: req.params.id } });

    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ============= COMMITS =============

// Create commit (text only)
app.post('/ideas/:ideaId/commits', authenticate, async (req: any, res) => {
  try {
    const { text } = req.body;
    const idea = await prisma.idea.findFirst({
      where: { id: req.params.ideaId, owner_id: req.user.id }
    });
    if (!idea) return res.status(404).json({ error: 'Idea not found' });

    const commit = await prisma.commit.create({
      data: {
        idea_id: req.params.ideaId,
        author_id: req.user.id,
        text,
        via: 'app'
      }
    });

    // Update idea's updated_at
    await prisma.idea.update({
      where: { id: req.params.ideaId },
      data: { updated_at: new Date() }
    });

    res.json(commit);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Upload audio commit
app.post('/ideas/:ideaId/commits/audio', authenticate, upload.single('audio'), async (req: any, res) => {
  try {
    const idea = await prisma.idea.findFirst({
      where: { id: req.params.ideaId, owner_id: req.user.id }
    });
    if (!idea) return res.status(404).json({ error: 'Idea not found' });

    if (!req.file) return res.status(400).json({ error: 'No audio file uploaded' });

    const audioUrl = `/uploads/${req.file.filename}`;
    const commit = await prisma.commit.create({
      data: {
        idea_id: req.params.ideaId,
        author_id: req.user.id,
        audio_url: audioUrl,
        duration_sec: parseInt(req.body.duration_sec || '0'),
        text: null, // Will be filled by transcription
        via: 'app'
      }
    });

    // Update idea's updated_at
    await prisma.idea.update({
      where: { id: req.params.ideaId },
      data: { updated_at: new Date() }
    });

    // TODO: Trigger transcription job here (Whisper API)
    // For now, return commit without transcript
    res.json(commit);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get commits for idea
app.get('/ideas/:ideaId/commits', authenticate, async (req: any, res) => {
  try {
    const idea = await prisma.idea.findFirst({
      where: { id: req.params.ideaId, owner_id: req.user.id }
    });
    if (!idea) return res.status(404).json({ error: 'Idea not found' });

    const commits = await prisma.commit.findMany({
      where: { idea_id: req.params.ideaId },
      orderBy: { created_at: 'asc' }
    });
    res.json(commits);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ============= HEALTH CHECK =============

app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

// Start server
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`API живёт на http://0.0.0.0:${PORT}`));
