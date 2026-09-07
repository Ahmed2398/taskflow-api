const { io } = require('socket.io-client');

const BASE_URL = process.argv[2] || 'http://localhost:3000';
const TOKEN = process.argv[3];
const BOARD_ID = process.argv[4];

if (!TOKEN || !BOARD_ID) {
  console.error('Usage: node test-ws.js <baseUrl> <accessToken> <boardId>');
  process.exit(1);
}

const socket = io(BASE_URL, {
  auth: { token: TOKEN },
});

socket.on('connect', () => {
  console.log('CONNECTED');
  socket.emit('board:join', { boardId: BOARD_ID });
});

socket.on('board:joined', (data) => {
  console.log('JOINED_BOARD', JSON.stringify(data));
});

socket.on('task:created', (task) => {
  console.log('TASK_CREATED', JSON.stringify(task));
});

socket.on('task:updated', (task) => {
  console.log('TASK_UPDATED', JSON.stringify(task));
});

socket.on('task:deleted', (data) => {
  console.log('TASK_DELETED', JSON.stringify(data));
});

socket.on('error', (err) => {
  console.log('ERROR', err);
});

socket.on('disconnect', () => {
  console.log('DISCONNECTED');
});

// Keep alive for 30 seconds
setTimeout(() => {
  console.log('TIMEOUT');
  socket.disconnect();
  process.exit(0);
}, 30000);
