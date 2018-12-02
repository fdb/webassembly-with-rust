const fs = require('fs');
const assert = require('assert');

const BLACK = 1;
const WHITE = 2;
const CROWN = 4;

describe('Checkers', () => {
  let checkers;
  let notifications;

  beforeEach(async () => {
    const buffer = fs.readFileSync('checkers.wasm');
    const events = {
      pieceCrowned: (x, y) => notifications.push({ type: 'pieceCrowned', x, y })
    };
    const wasm = await WebAssembly.instantiate(buffer, { events });
    checkers = wasm.instance.exports;
    notifications = [];
  });

  it('tests turns', () => {
    assert.strictEqual(typeof checkers.getTurnOwner, 'function');
    // The turn owner starts out as 0.
    assert.strictEqual(checkers.getTurnOwner(), 0);
    // Setting it to white is stored.
    checkers.setTurnOwner(WHITE);
    assert.strictEqual(checkers.getTurnOwner(), WHITE);
    // Toggling the turn owner flips it to black.
    checkers.toggleTurnOwner();
    assert.strictEqual(checkers.getTurnOwner(), BLACK);
    // Check if it's the players turn.
    const player = BLACK;
    assert.strictEqual(checkers.isPlayersTurn(player), 1);
  });

  it('should crown', () => {
    assert.strictEqual(checkers.shouldCrown(0, BLACK), 1);
    assert.strictEqual(checkers.shouldCrown(5, BLACK), 0);
    assert.strictEqual(checkers.shouldCrown(7, BLACK), 0);

    assert.strictEqual(checkers.shouldCrown(0, WHITE), 0);
    assert.strictEqual(checkers.shouldCrown(5, WHITE), 0);
    assert.strictEqual(checkers.shouldCrown(7, WHITE), 1);
  });

  it('can crown a piece', () => {
    checkers.setPiece(0, 0, BLACK);
    assert.strictEqual(checkers.isCrowned(checkers.getPiece(0, 0)), 0);
    checkers.crownPiece(0, 0);
    assert.strictEqual(checkers.isCrowned(checkers.getPiece(0, 0)), 1);
    assert.strictEqual(notifications.length, 1);
    assert.deepStrictEqual(notifications[0], { type: 'pieceCrowned', x: 0, y: 0 });
  });

  it('can check for a valid move', () => {
    checkers.setPiece(5, 0, BLACK);
    // isValidMove checks if it's our turn.
    // If we haven't set turn owner, the move will always be invalid.
    assert.strictEqual(checkers.isValidMove(5, 0, 5, 1), 0);
    checkers.setTurnOwner(BLACK);
    // We can only jump 1 or two squares.
    assert.strictEqual(checkers.isValidMove(5, 0, 5, 1), 1);
    assert.strictEqual(checkers.isValidMove(5, 0, 5, 2), 1);
    assert.strictEqual(checkers.isValidMove(5, 0, 5, 3), 0);
  });

});
