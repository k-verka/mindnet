import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

// Создать тестового юзера
app.post('/users', async (req, res) => {
  const { name = 'k-verka' } = req.body;
  const user = await prisma.user.create({
    data: { name, slots_free: 7, slots_total: 7 }
  });
  res.json(user);
});

app.listen(4000, () => console.log('API живёт на http://0.0.0.0:4000'));
