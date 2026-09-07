const { io } = require('socket.io-client');

const BASE_URL = process.argv[2] || 'http://localhost:3000';

const socket = io(BASE_URL, { auth: { token: 'invalid-token' } });

let gotError = false;

socket.on('error', (err) => {
  gotError = true;
  console.log('ERROR_RECEIVED:', err);
  process.exit(0);
});

socket.on('connect', () => {
  // Server may connect then immediately disconnect with error
  // Wait a bit to see if error arrives
  setTimeout(() => {
    if (!gotError) {
      console.log('SHOULD_NOT_CONNECT');
      process.exit(1);
    }
  }, 1000);
});

setTimeout(() => {
  if (!gotError) {
    console.log('TIMEOUT_NO_ERROR');
    process.exit(1);
  }
}, 5000);

