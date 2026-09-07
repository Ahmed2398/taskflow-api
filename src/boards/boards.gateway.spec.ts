import { Test, TestingModule } from '@nestjs/testing';
import { BoardsGateway } from './boards.gateway.js';

describe('BoardsGateway', () => {
  let gateway: BoardsGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [BoardsGateway],
    }).compile();

    gateway = module.get<BoardsGateway>(BoardsGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
