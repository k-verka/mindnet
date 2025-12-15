import React, { useState, useMemo } from 'react';
import { Plus, Circle, GitBranch } from 'lucide-react';

const Mindnet = () => {
  const [nodes, setNodes] = useState(() => {
    const mainNode = {
      id: 'main',
      parentId: null,
      createdAt: Date.now(),
      x: 0,
      y: 0,
      text: 'Main Node',
      status: 'neutral' // neutral, thinking, resolved, overthinking
    };
    
    return [mainNode];
  });
  
  const [selectedNodeId, setSelectedNodeId] = useState('main');
  const [showModal, setShowModal] = useState(false);
  const [editingNode, setEditingNode] = useState(null);
  const [modalText, setModalText] = useState('');
  const [scale, setScale] = useState(1);
  const [panOffset, setPanOffset] = useState({ x: 0, y: 0 });
  const [isPanning, setIsPanning] = useState(false);
  const [startPan, setStartPan] = useState({ x: 0, y: 0 });
  
  // Найти самый последний узел в системе (максимальный Y)
  const getLastNode = () => {
    return nodes.reduce((max, node) => node.y > max.y ? node : max, nodes[0]);
  };
  
  // Найти самый последний узел основной ветки (X=0)
  const getLastMainBranchNode = () => {
    const mainBranchNodes = nodes.filter(n => n.x === 0);
    return mainBranchNodes.reduce((max, node) => node.y > max.y ? node : max, mainBranchNodes[0]);
  };
  
  // Проверить, является ли узел последним на основной ветке
  const isLastMainBranchNode = (nodeId) => {
    const lastMainNode = getLastMainBranchNode();
    return nodeId === lastMainNode.id;
  };
  
  // Определить свободное X для ответвления
  const findFreeX = (parentX, targetY) => {
    const occupiedX = nodes
      .filter(n => n.y === targetY)
      .map(n => n.x);
    
    // Попробовать справа и слева от родителя
    for (let offset of [1, -1, 2, -2, 3, -3]) {
      const candidateX = parentX + offset;
      if (!occupiedX.includes(candidateX)) {
        return candidateX;
      }
    }
    
    return parentX + 1;
  };
  
  const addNode = () => {
    const selectedNode = nodes.find(n => n.id === selectedNodeId);
    if (!selectedNode) return;
    
    const lastNode = getLastNode();
    const newY = lastNode.y + 1;
    
    let newX;
    let parentId = selectedNodeId;
    
    if (isLastMainBranchNode(selectedNodeId)) {
      // Продолжаем основную ветку
      newX = 0;
    } else {
      // Создаём ответвление
      newX = findFreeX(selectedNode.x, newY);
    }
    
    const newNode = {
      id: `node-${Date.now()}-${Math.random()}`,
      parentId,
      createdAt: Date.now(),
      x: newX,
      y: newY,
      text: '',
      status: 'neutral',
      isNew: true // Флаг для анимации
    };
    
    setNodes([...nodes, newNode]);
    setSelectedNodeId(newNode.id);
    
    // Убираем флаг анимации через 600мс
    setTimeout(() => {
      setNodes(prev => prev.map(n => 
        n.id === newNode.id ? { ...n, isNew: false } : n
      ));
    }, 600);
  };
  
  const deleteNode = (nodeId) => {
    if (nodeId === 'main') return; // Нельзя удалить главный узел
    
    // Находим все дочерние узлы (всю ветку)
    const findChildren = (id) => {
      const children = nodes.filter(n => n.parentId === id);
      return [id, ...children.flatMap(child => findChildren(child.id))];
    };
    
    const toDelete = findChildren(nodeId);
    setNodes(prev => prev.filter(n => !toDelete.includes(n.id)));
    
    // Сброс выделения
    if (toDelete.includes(selectedNodeId)) {
      setSelectedNodeId('main');
    }
  };
  
  const openEditModal = (node) => {
    setEditingNode(node);
    setModalText(node.text || '');
    setShowModal(true);
  };
  
  const saveNodeEdit = () => {
    if (!editingNode) return;
    
    setNodes(prev => prev.map(n => 
      n.id === editingNode.id 
        ? { ...n, text: modalText, createdAt: Date.now() } 
        : n
    ));
    
    setShowModal(false);
    setEditingNode(null);
    setModalText('');
  };
  
  const handleNodeClick = (nodeId, e) => {
    e.stopPropagation();
    setSelectedNodeId(nodeId);
  };
  
  // Вычисляем границы для отрисовки
  const bounds = useMemo(() => {
    const xs = nodes.map(n => n.x);
    const ys = nodes.map(n => n.y);
    return {
      minX: Math.min(...xs),
      maxX: Math.max(...xs),
      minY: Math.min(...ys),
      maxY: Math.max(...ys)
    };
  }, [nodes]);
  
  // Размеры сетки
  const CELL_WIDTH = 80;
  const CELL_HEIGHT = 100;
  const NODE_RADIUS = 24;
  const LEFT_PADDING = 120; // Отступ слева для временной шкалы
  
  // Преобразование координат узла в пиксели
  const getNodePosition = (node) => {
    const offsetX = Math.abs(bounds.minX);
    return {
      x: LEFT_PADDING + (node.x + offsetX) * CELL_WIDTH,
      y: (node.y - bounds.minY) * CELL_HEIGHT + 50
    };
  };
  
  // Генерация линий связей
  const renderConnections = () => {
    return nodes
      .filter(node => node.parentId)
      .map(node => {
        const parent = nodes.find(n => n.id === node.parentId);
        if (!parent) return null;
        
        const childPos = getNodePosition(node);
        const parentPos = getNodePosition(parent);
        
        const isVertical = node.x === parent.x;
        
        if (isVertical) {
          // Прямая вертикальная линия
          return (
            <line
              key={`line-${node.id}`}
              x1={parentPos.x}
              y1={parentPos.y + NODE_RADIUS}
              x2={childPos.x}
              y2={childPos.y - NODE_RADIUS}
              stroke="rgba(147, 197, 253, 0.4)"
              strokeWidth="2"
            />
          );
        } else {
          // L-образное соединение для ответвления: сначала ВПРАВО, потом ВНИЗ
          const cornerX = childPos.x;
          const cornerY = parentPos.y + NODE_RADIUS + 20; // Небольшой отступ от родителя
          
          return (
            <g key={`line-${node.id}`}>
              {/* Вертикальная часть от родителя до угла */}
              <line
                x1={parentPos.x}
                y1={parentPos.y + NODE_RADIUS}
                x2={parentPos.x}
                y2={cornerY}
                stroke="rgba(147, 197, 253, 0.4)"
                strokeWidth="2"
              />
              {/* Горизонтальная часть */}
              <line
                x1={parentPos.x}
                y1={cornerY}
                x2={cornerX}
                y2={cornerY}
                stroke="rgba(147, 197, 253, 0.4)"
                strokeWidth="2"
              />
              {/* Вертикальная часть до дочернего узла */}
              <line
                x1={cornerX}
                y1={cornerY}
                x2={childPos.x}
                y2={childPos.y - NODE_RADIUS}
                stroke="rgba(147, 197, 253, 0.4)"
                strokeWidth="2"
              />
            </g>
          );
        }
      });
  };
  
  // Отрисовка вертикальных линий для веток между узлами
  const renderBranchLines = () => {
    const lines = [];
    
    // Группируем узлы по X (по веткам)
    const branchesByX = {};
    nodes.forEach(node => {
      if (!branchesByX[node.x]) {
        branchesByX[node.x] = [];
      }
      branchesByX[node.x].push(node);
    });
    
    // Для каждой ветки рисуем промежуточные линии
    Object.entries(branchesByX).forEach(([x, branchNodes]) => {
      const sortedNodes = branchNodes.sort((a, b) => a.y - b.y);
      
      for (let i = 0; i < sortedNodes.length - 1; i++) {
        const current = sortedNodes[i];
        const next = sortedNodes[i + 1];
        
        // Если между узлами есть пропуск по Y
        if (next.y - current.y > 1) {
          const currentPos = getNodePosition(current);
          const nextPos = getNodePosition(next);
          
          lines.push(
            <line
              key={`branch-${current.id}-${next.id}`}
              x1={currentPos.x}
              y1={currentPos.y + NODE_RADIUS}
              x2={nextPos.x}
              y2={nextPos.y - NODE_RADIUS}
              stroke="rgba(147, 197, 253, 0.2)"
              strokeWidth="2"
              strokeDasharray="4 4"
            />
          );
        }
      }
    });
    
    return lines;
  };
  
  const handleWheel = (e) => {
    if (e.ctrlKey || e.metaKey) {
      e.preventDefault();
      const delta = e.deltaY * -0.001;
      const newScale = Math.min(Math.max(0.3, scale + delta), 3);
      setScale(newScale);
    }
  };
  
  const handleMouseDown = (e) => {
    if (e.button === 0 && (e.ctrlKey || e.metaKey)) {
      setIsPanning(true);
      setStartPan({ x: e.clientX - panOffset.x, y: e.clientY - panOffset.y });
    }
  };
  
  const handleMouseMove = (e) => {
    if (isPanning) {
      setPanOffset({
        x: e.clientX - startPan.x,
        y: e.clientY - startPan.y
      });
    }
  };
  
  const handleMouseUp = () => {
    setIsPanning(false);
  };
  
  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
  };
  
  const getStatusColor = (status) => {
    switch (status) {
      case 'thinking': return '#fbbf24'; // yellow
      case 'resolved': return '#34d399'; // green
      case 'overthinking': return '#f87171'; // red
      default: return '#93c5fd'; // blue
    }
  };
  
  const svgWidth = LEFT_PADDING + (bounds.maxX - bounds.minX + 1) * CELL_WIDTH + 100;
  const svgHeight = (bounds.maxY - bounds.minY + 1) * CELL_HEIGHT + 100;
  
  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%)',
      fontFamily: '"IBM Plex Mono", "JetBrains Mono", monospace',
      color: '#e2e8f0',
      overflow: 'hidden',
      position: 'relative'
    }}>
      {/* Фоновая сетка */}
      <div style={{
        position: 'absolute',
        inset: 0,
        backgroundImage: `
          linear-gradient(rgba(148, 163, 184, 0.03) 1px, transparent 1px),
          linear-gradient(90deg, rgba(148, 163, 184, 0.03) 1px, transparent 1px)
        `,
        backgroundSize: '40px 40px',
        pointerEvents: 'none'
      }} />
      
      {/* Заголовок */}
      <header style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        background: 'rgba(15, 23, 42, 0.85)',
        backdropFilter: 'blur(12px)',
        borderBottom: '1px solid rgba(148, 163, 184, 0.1)',
        padding: '20px 40px'
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          maxWidth: '1600px',
          margin: '0 auto'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <GitBranch size={28} color="#60a5fa" strokeWidth={2.5} />
            <h1 style={{
              margin: 0,
              fontSize: '28px',
              fontWeight: 700,
              letterSpacing: '-0.02em',
              background: 'linear-gradient(135deg, #60a5fa 0%, #a78bfa 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text'
            }}>
              MINDNET
            </h1>
            <span style={{
              fontSize: '13px',
              color: '#64748b',
              letterSpacing: '0.05em',
              textTransform: 'uppercase'
            }}>
              Thought Evolution System
            </span>
          </div>
          
          <button
            onClick={addNode}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '12px 24px',
              background: 'linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%)',
              border: 'none',
              borderRadius: '8px',
              color: 'white',
              fontSize: '14px',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              boxShadow: '0 4px 12px rgba(59, 130, 246, 0.3)',
              fontFamily: 'inherit',
              letterSpacing: '0.02em'
            }}
            onMouseEnter={(e) => {
              e.target.style.transform = 'translateY(-2px)';
              e.target.style.boxShadow = '0 6px 20px rgba(59, 130, 246, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.target.style.transform = 'translateY(0)';
              e.target.style.boxShadow = '0 4px 12px rgba(59, 130, 246, 0.3)';
            }}
          >
            <Plus size={18} />
            Add Node
          </button>
        </div>
      </header>
      
      {/* Информационная панель */}
      <div style={{
        maxWidth: '1600px',
        margin: '0 auto',
        padding: '24px 40px'
      }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '16px',
          marginBottom: '32px'
        }}>
          <div style={{
            background: 'rgba(30, 41, 59, 0.6)',
            border: '1px solid rgba(148, 163, 184, 0.1)',
            borderRadius: '12px',
            padding: '16px 20px',
            backdropFilter: 'blur(8px)'
          }}>
            <div style={{ fontSize: '12px', color: '#94a3b8', marginBottom: '4px', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
              Total Nodes
            </div>
            <div style={{ fontSize: '32px', fontWeight: 700, color: '#60a5fa' }}>
              {nodes.length}
            </div>
          </div>
          
          <div style={{
            background: 'rgba(30, 41, 59, 0.6)',
            border: '1px solid rgba(148, 163, 184, 0.1)',
            borderRadius: '12px',
            padding: '16px 20px',
            backdropFilter: 'blur(8px)'
          }}>
            <div style={{ fontSize: '12px', color: '#94a3b8', marginBottom: '4px', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
              Branches
            </div>
            <div style={{ fontSize: '32px', fontWeight: 700, color: '#a78bfa' }}>
              {new Set(nodes.map(n => n.x)).size}
            </div>
          </div>
          
          <div style={{
            background: 'rgba(30, 41, 59, 0.6)',
            border: '1px solid rgba(148, 163, 184, 0.1)',
            borderRadius: '12px',
            padding: '16px 20px',
            backdropFilter: 'blur(8px)'
          }}>
            <div style={{ fontSize: '12px', color: '#94a3b8', marginBottom: '4px', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
              Selected
            </div>
            <div style={{ fontSize: '20px', fontWeight: 600, color: '#e2e8f0', marginTop: '8px' }}>
              {selectedNodeId === 'main' ? 'Main Node' : `Node ${nodes.findIndex(n => n.id === selectedNodeId) + 1}`}
            </div>
          </div>
        </div>
      </div>
      
      {/* Граф узлов */}
      <div style={{
        maxWidth: '1600px',
        margin: '0 auto',
        padding: '0 40px 60px'
      }}>
        <div 
          style={{
            background: 'rgba(30, 41, 59, 0.4)',
            border: '1px solid rgba(148, 163, 184, 0.1)',
            borderRadius: '16px',
            padding: '40px',
            backdropFilter: 'blur(8px)',
            overflowX: 'auto',
            overflowY: 'auto',
            maxHeight: '70vh',
            cursor: isPanning ? 'grabbing' : 'grab',
            position: 'relative'
          }}
          onWheel={handleWheel}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
        >
          <div style={{
            transform: `scale(${scale}) translate(${panOffset.x / scale}px, ${panOffset.y / scale}px)`,
            transformOrigin: 'center center',
            transition: isPanning ? 'none' : 'transform 0.1s ease-out'
          }}>
            <svg
              width={svgWidth}
              height={svgHeight}
              style={{ display: 'block', margin: '0 auto' }}
            >
            {/* Временная шкала слева */}
            <g>
              {nodes.map((node, index) => {
                const yPos = (node.y - bounds.minY) * CELL_HEIGHT + 50;
                
                return (
                  <g key={`timeline-${node.id}`}>
                    {/* Горизонтальная линия шкалы */}
                    <line
                      x1={10}
                      y1={yPos}
                      x2={LEFT_PADDING - 35}
                      y2={yPos}
                      stroke="rgba(148, 163, 184, 0.2)"
                      strokeWidth="1"
                      strokeDasharray="2 2"
                    />
                    
                    {/* Метка на шкале */}
                    <circle
                      cx={LEFT_PADDING - 35}
                      cy={yPos}
                      r={3}
                      fill="#64748b"
                    />
                    
                    {/* Время */}
                    <text
                      x={LEFT_PADDING - 45}
                      y={yPos + 4}
                      textAnchor="end"
                      style={{
                        fontSize: '11px',
                        fill: '#94a3b8',
                        fontFamily: 'inherit',
                        fontWeight: 500
                      }}
                    >
                      {formatTime(node.createdAt)}
                    </text>
                  </g>
                );
              })}
              
              {/* Вертикальная линия временной шкалы */}
              <line
                x1={LEFT_PADDING - 35}
                y1={50}
                x2={LEFT_PADDING - 35}
                y2={(bounds.maxY - bounds.minY) * CELL_HEIGHT + 50}
                stroke="rgba(148, 163, 184, 0.3)"
                strokeWidth="2"
              />
              
              {/* Заголовок временной шкалы */}
              <text
                x={LEFT_PADDING - 45}
                y={25}
                textAnchor="end"
                style={{
                  fontSize: '10px',
                  fill: '#64748b',
                  fontFamily: 'inherit',
                  letterSpacing: '0.05em',
                  textTransform: 'uppercase',
                  fontWeight: 600
                }}
              >
                Timeline
              </text>
            </g>
            
            {/* Линии веток */}
            {renderBranchLines()}
            
            {/* Соединения между узлами */}
            {renderConnections()}
            
            {/* Узлы */}
            {nodes.map((node) => {
              const pos = getNodePosition(node);
              const isSelected = node.id === selectedNodeId;
              const isMainNode = node.id === 'main';
              const isMainBranch = node.x === 0;
              const statusColor = getStatusColor(node.status);
              
              return (
                <g
                  key={node.id}
                  transform={`translate(${pos.x}, ${pos.y})`}
                  onClick={(e) => handleNodeClick(node.id, e)}
                  style={{ 
                    cursor: 'pointer',
                    animation: node.isNew ? 'nodeAppear 0.6s ease-out' : 'none'
                  }}
                >
                  {/* Свечение при выборе */}
                  {isSelected && (
                    <>
                      <circle
                        r={NODE_RADIUS + 8}
                        fill="none"
                        stroke="#60a5fa"
                        strokeWidth="2"
                        opacity="0.3"
                        style={{
                          animation: 'pulse 2s ease-in-out infinite'
                        }}
                      />
                      
                      {/* Контекстное меню при выборе */}
                      <g transform={`translate(${NODE_RADIUS + 15}, -30)`}>
                        {/* Редактировать */}
                        <g 
                          onClick={(e) => {
                            e.stopPropagation();
                            openEditModal(node);
                          }}
                          style={{ cursor: 'pointer' }}
                        >
                          <rect
                            x="0"
                            y="0"
                            width="28"
                            height="28"
                            rx="6"
                            fill="rgba(59, 130, 246, 0.9)"
                            style={{
                              transition: 'all 0.2s ease'
                            }}
                            onMouseEnter={(e) => e.target.setAttribute('fill', 'rgba(59, 130, 246, 1)')}
                            onMouseLeave={(e) => e.target.setAttribute('fill', 'rgba(59, 130, 246, 0.9)')}
                          />
                          <text
                            x="14"
                            y="18"
                            textAnchor="middle"
                            style={{
                              fontSize: '16px',
                              fill: 'white',
                              pointerEvents: 'none'
                            }}
                          >
                            ✏️
                          </text>
                        </g>
                        
                        {/* Добавить ребёнка */}
                        <g 
                          onClick={(e) => {
                            e.stopPropagation();
                            addNode();
                          }}
                          style={{ cursor: 'pointer' }}
                          transform="translate(35, 0)"
                        >
                          <rect
                            x="0"
                            y="0"
                            width="28"
                            height="28"
                            rx="6"
                            fill="rgba(34, 197, 94, 0.9)"
                            style={{
                              transition: 'all 0.2s ease'
                            }}
                            onMouseEnter={(e) => e.target.setAttribute('fill', 'rgba(34, 197, 94, 1)')}
                            onMouseLeave={(e) => e.target.setAttribute('fill', 'rgba(34, 197, 94, 0.9)')}
                          />
                          <text
                            x="14"
                            y="18"
                            textAnchor="middle"
                            style={{
                              fontSize: '16px',
                              fill: 'white',
                              pointerEvents: 'none'
                            }}
                          >
                            ➕
                          </text>
                        </g>
                        
                        {/* Удалить ветку */}
                        {!isMainNode && (
                          <g 
                            onClick={(e) => {
                              e.stopPropagation();
                              if (window.confirm('Delete this node and its children?')) {
                                deleteNode(node.id);
                              }
                            }}
                            style={{ cursor: 'pointer' }}
                            transform="translate(70, 0)"
                          >
                            <rect
                              x="0"
                              y="0"
                              width="28"
                              height="28"
                              rx="6"
                              fill="rgba(239, 68, 68, 0.9)"
                              style={{
                                transition: 'all 0.2s ease'
                              }}
                              onMouseEnter={(e) => e.target.setAttribute('fill', 'rgba(239, 68, 68, 1)')}
                              onMouseLeave={(e) => e.target.setAttribute('fill', 'rgba(239, 68, 68, 0.9)')}
                            />
                            <text
                              x="14"
                              y="18"
                              textAnchor="middle"
                              style={{
                                fontSize: '16px',
                                fill: 'white',
                                pointerEvents: 'none'
                              }}
                            >
                              🗑️
                            </text>
                          </g>
                        )}
                      </g>
                    </>
                  )}
                  
                  {/* Внешнее кольцо */}
                  <circle
                    r={NODE_RADIUS}
                    fill={isMainNode ? 'rgba(59, 130, 246, 0.2)' : 'rgba(30, 41, 59, 0.8)'}
                    stroke={isSelected ? '#60a5fa' : (isMainBranch ? 'rgba(96, 165, 250, 0.6)' : 'rgba(148, 163, 184, 0.4)')}
                    strokeWidth={isSelected ? '3' : '2'}
                    style={{
                      filter: isSelected ? 'drop-shadow(0 0 12px rgba(96, 165, 250, 0.6))' : 'none',
                      transition: 'all 0.3s ease'
                    }}
                  />
                  
                  {/* Иконка внутри узла с цветом статуса */}
                  <circle
                    r={isMainNode ? 8 : 6}
                    fill={statusColor}
                    style={{
                      filter: isMainNode ? `drop-shadow(0 0 4px ${statusColor})` : 'none'
                    }}
                  />
                  
                  {/* Индикатор текста */}
                  {node.text && (
                    <circle
                      cx={NODE_RADIUS - 6}
                      cy={-NODE_RADIUS + 6}
                      r={4}
                      fill="#22c55e"
                      stroke="rgba(30, 41, 59, 0.8)"
                      strokeWidth="2"
                    />
                  )}
                  
                  {/* Номер узла */}
                  {!isMainNode && (
                    <text
                      y={NODE_RADIUS + 20}
                      textAnchor="middle"
                      style={{
                        fontSize: '10px',
                        fill: '#94a3b8',
                        fontFamily: 'inherit',
                        pointerEvents: 'none'
                      }}
                    >
                      #{nodes.findIndex(n => n.id === node.id) + 1}
                    </text>
                  )}
                </g>
              );
            })}
          </svg>
          </div>
          
          {/* Zoom controls */}
          <div style={{
            position: 'absolute',
            bottom: '20px',
            right: '20px',
            display: 'flex',
            flexDirection: 'column',
            gap: '8px',
            background: 'rgba(30, 41, 59, 0.9)',
            padding: '8px',
            borderRadius: '8px',
            border: '1px solid rgba(148, 163, 184, 0.2)'
          }}>
            <button
              onClick={() => setScale(Math.min(scale + 0.2, 3))}
              style={{
                width: '32px',
                height: '32px',
                background: 'rgba(59, 130, 246, 0.8)',
                border: 'none',
                borderRadius: '4px',
                color: 'white',
                cursor: 'pointer',
                fontSize: '18px',
                fontWeight: 'bold'
              }}
            >
              +
            </button>
            <div style={{
              fontSize: '11px',
              color: '#94a3b8',
              textAlign: 'center',
              padding: '4px 0'
            }}>
              {Math.round(scale * 100)}%
            </div>
            <button
              onClick={() => setScale(Math.max(scale - 0.2, 0.3))}
              style={{
                width: '32px',
                height: '32px',
                background: 'rgba(59, 130, 246, 0.8)',
                border: 'none',
                borderRadius: '4px',
                color: 'white',
                cursor: 'pointer',
                fontSize: '18px',
                fontWeight: 'bold'
              }}
            >
              −
            </button>
            <button
              onClick={() => {
                setScale(1);
                setPanOffset({ x: 0, y: 0 });
              }}
              style={{
                width: '32px',
                height: '32px',
                background: 'rgba(148, 163, 184, 0.8)',
                border: 'none',
                borderRadius: '4px',
                color: 'white',
                cursor: 'pointer',
                fontSize: '16px'
              }}
            >
              ⟲
            </button>
          </div>
          
          {/* Pan hint */}
          <div style={{
            position: 'absolute',
            bottom: '20px',
            left: '20px',
            fontSize: '11px',
            color: '#64748b',
            background: 'rgba(30, 41, 59, 0.9)',
            padding: '8px 12px',
            borderRadius: '6px',
            border: '1px solid rgba(148, 163, 184, 0.2)'
          }}>
            💡 Ctrl+Scroll to zoom • Ctrl+Drag to pan
          </div>
        </div>
        
        {/* Легенда */}
        <div style={{
          marginTop: '24px',
          display: 'flex',
          gap: '32px',
          justifyContent: 'center',
          fontSize: '13px',
          color: '#94a3b8'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{
              width: '16px',
              height: '16px',
              borderRadius: '50%',
              background: '#60a5fa',
              boxShadow: '0 0 8px rgba(96, 165, 250, 0.6)'
            }} />
            Main Branch (X=0)
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{
              width: '16px',
              height: '16px',
              borderRadius: '50%',
              background: '#a78bfa'
            }} />
            Side Branches
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{
              width: '32px',
              height: '2px',
              background: 'rgba(147, 197, 253, 0.4)'
            }} />
            Connection
          </div>
        </div>
      </div>
      
      {/* Модальное окно редактирования */}
      {showModal && (
        <div 
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.7)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            animation: 'fadeIn 0.2s ease-out'
          }}
          onClick={() => setShowModal(false)}
        >
          <div 
            style={{
              background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
              border: '1px solid rgba(148, 163, 184, 0.2)',
              borderRadius: '16px',
              padding: '32px',
              maxWidth: '600px',
              width: '90%',
              boxShadow: '0 20px 60px rgba(0, 0, 0, 0.5)',
              animation: 'slideUp 0.3s ease-out'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h2 style={{
              margin: '0 0 24px 0',
              fontSize: '24px',
              fontWeight: 700,
              color: '#e2e8f0',
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}>
              <span style={{
                width: '32px',
                height: '32px',
                background: 'linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%)',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '18px'
              }}>
                ✏️
              </span>
              Edit Node
            </h2>
            
            <div style={{ marginBottom: '24px' }}>
              <label style={{
                display: 'block',
                fontSize: '13px',
                color: '#94a3b8',
                marginBottom: '8px',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
                fontWeight: 600
              }}>
                Thought Content
              </label>
              <textarea
                value={modalText}
                onChange={(e) => setModalText(e.target.value)}
                placeholder="Write your thought here..."
                autoFocus
                style={{
                  width: '100%',
                  minHeight: '150px',
                  padding: '16px',
                  background: 'rgba(15, 23, 42, 0.6)',
                  border: '1px solid rgba(148, 163, 184, 0.2)',
                  borderRadius: '12px',
                  color: '#e2e8f0',
                  fontSize: '15px',
                  fontFamily: 'inherit',
                  resize: 'vertical',
                  outline: 'none',
                  transition: 'all 0.2s ease'
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = '#60a5fa';
                  e.target.style.boxShadow = '0 0 0 3px rgba(96, 165, 250, 0.1)';
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = 'rgba(148, 163, 184, 0.2)';
                  e.target.style.boxShadow = 'none';
                }}
              />
            </div>
            
            <div style={{
              marginBottom: '24px',
              display: 'flex',
              gap: '12px',
              flexWrap: 'wrap'
            }}>
              <label style={{
                display: 'block',
                fontSize: '13px',
                color: '#94a3b8',
                marginBottom: '8px',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
                fontWeight: 600,
                width: '100%'
              }}>
                Status
              </label>
              {['neutral', 'thinking', 'resolved', 'overthinking'].map(status => (
                <button
                  key={status}
                  onClick={() => {
                    setNodes(prev => prev.map(n => 
                      n.id === editingNode.id ? { ...n, status } : n
                    ));
                  }}
                  style={{
                    padding: '8px 16px',
                    background: editingNode?.status === status 
                      ? `linear-gradient(135deg, ${getStatusColor(status)}, ${getStatusColor(status)}dd)` 
                      : 'rgba(30, 41, 59, 0.6)',
                    border: `2px solid ${editingNode?.status === status ? getStatusColor(status) : 'rgba(148, 163, 184, 0.2)'}`,
                    borderRadius: '8px',
                    color: 'white',
                    fontSize: '13px',
                    fontWeight: 600,
                    cursor: 'pointer',
                    fontFamily: 'inherit',
                    textTransform: 'capitalize',
                    transition: 'all 0.2s ease'
                  }}
                >
                  {status}
                </button>
              ))}
            </div>
            
            <div style={{
              display: 'flex',
              gap: '12px',
              justifyContent: 'flex-end'
            }}>
              <button
                onClick={() => setShowModal(false)}
                style={{
                  padding: '12px 24px',
                  background: 'rgba(148, 163, 184, 0.2)',
                  border: '1px solid rgba(148, 163, 184, 0.3)',
                  borderRadius: '8px',
                  color: '#e2e8f0',
                  fontSize: '14px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontFamily: 'inherit',
                  transition: 'all 0.2s ease'
                }}
              >
                Cancel
              </button>
              <button
                onClick={saveNodeEdit}
                style={{
                  padding: '12px 24px',
                  background: 'linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%)',
                  border: 'none',
                  borderRadius: '8px',
                  color: 'white',
                  fontSize: '14px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontFamily: 'inherit',
                  boxShadow: '0 4px 12px rgba(59, 130, 246, 0.3)',
                  transition: 'all 0.2s ease'
                }}
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}
      
      {/* CSS анимация */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600;700&display=swap');
        
        @keyframes pulse {
          0%, 100% {
            opacity: 0.3;
            transform: scale(1);
          }
          50% {
            opacity: 0.6;
            transform: scale(1.1);
          }
        }
        
        @keyframes nodeAppear {
          0% {
            opacity: 0;
            transform: scale(0.5);
          }
          60% {
            transform: scale(1.1);
          }
          100% {
            opacity: 1;
            transform: scale(1);
          }
        }
        
        @keyframes fadeIn {
          from {
            opacity: 0;
          }
          to {
            opacity: 1;
          }
        }
        
        @keyframes slideUp {
          from {
            transform: translateY(40px);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }
        
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          overflow-x: hidden;
        }
        
        textarea::-webkit-scrollbar {
          width: 8px;
        }
        
        textarea::-webkit-scrollbar-track {
          background: rgba(15, 23, 42, 0.4);
          border-radius: 4px;
        }
        
        textarea::-webkit-scrollbar-thumb {
          background: rgba(96, 165, 250, 0.4);
          border-radius: 4px;
        }
        
        textarea::-webkit-scrollbar-thumb:hover {
          background: rgba(96, 165, 250, 0.6);
        }
      `}</style>
    </div>
  );
};

export default Mindnet;
