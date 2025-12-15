import React, { useState, useMemo } from 'react';
import { Plus, Circle, GitBranch } from 'lucide-react';

const Mindnet = () => {
  const [nodes, setNodes] = useState(() => {
    const mainNode = {
      id: 'main',
      parentId: null,
      createdAt: Date.now(),
      x: 0,
      y: 0
    };
    
    return [mainNode];
  });
  
  const [selectedNodeId, setSelectedNodeId] = useState('main');
  
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
      y: newY
    };
    
    setNodes([...nodes, newNode]);
    setSelectedNodeId(newNode.id);
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
  
  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
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
        <div style={{
          background: 'rgba(30, 41, 59, 0.4)',
          border: '1px solid rgba(148, 163, 184, 0.1)',
          borderRadius: '16px',
          padding: '40px',
          backdropFilter: 'blur(8px)',
          overflowX: 'auto'
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
              
              return (
                <g
                  key={node.id}
                  transform={`translate(${pos.x}, ${pos.y})`}
                  onClick={() => setSelectedNodeId(node.id)}
                  style={{ cursor: 'pointer' }}
                >
                  {/* Свечение при выборе */}
                  {isSelected && (
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
                  
                  {/* Иконка внутри узла */}
                  <circle
                    r={isMainNode ? 8 : 6}
                    fill={isMainNode ? '#60a5fa' : (isMainBranch ? '#93c5fd' : '#a78bfa')}
                    style={{
                      filter: isMainNode ? 'drop-shadow(0 0 4px rgba(96, 165, 250, 0.8))' : 'none'
                    }}
                  />
                  
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
        
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          overflow-x: hidden;
        }
      `}</style>
    </div>
  );
};

export default Mindnet;
