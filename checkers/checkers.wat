;; Checkers engine
;; Core game board is 8x8
(module
  (import "events" "pieceCrowned" (func $notifyPieceCrowned (param $x i32) (param $y i32)))
  (import "events" "pieceMoved" (func $notifyPieceMoved (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32)))

  (memory $mem 1)
  (global $currentTurn (mut i32) (i32.const 0))

  (global $BLACK i32 (i32.const 1))
  (global $WHITE i32 (i32.const 2))
  (global $CROWN i32 (i32.const 4))

  ;; Index = x + y * 8
  (func $indexForPosition (param $x i32) (param $y i32) (result i32)
    (i32.add
      (i32.mul (i32.const 8) (get_local $y))
      (get_local $x))
  )

  ;; Offset = ( x + y * 8) * 4
  (func $offsetForPosition (param $x i32) (param $y i32) (result i32)
    (i32.mul
      (call $indexForPosition (get_local $x) (get_local $y))
      (i32.const 4)
    )
  )

  ;; Determine if a piece has been crowned
  (func $isCrowned (param $piece i32) (result i32)
    (i32.eq
      (i32.and (get_local $piece) (get_global $CROWN))
      (get_global $CROWN)
    )
  )

  ;; Determine if a piece is white
  (func $isWhite (param $piece i32) (result i32)
    (i32.eq
      (i32.and (get_local $piece) (get_global $WHITE))
      (get_global $WHITE)
    )
  )

  ;; Determine if a piece is black
  (func $isBlack (param $piece i32) (result i32)
    (i32.eq
      (i32.and (get_local $piece) (get_global $BLACK))
      (get_global $BLACK)
    )
  )

  ;; Add a crown to a given piece and return it
  (func $withCrown (param $piece i32) (result i32)
    (i32.or (get_local $piece) (get_global $CROWN))
  )

  ;; Remove a crown from a given piece and return it
  (func $withoutCrown (param $piece i32) (result i32)
    (i32.and (get_local $piece) (i32.const 3))
  )

  ;; Set a piece on the board
  (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
    (i32.store
      (call $offsetForPosition (get_local $x) (get_local $y))
      (get_local $piece)
    )
  )

  ;; Get a piece from the board.
  ;; Out of range causes a trap.
  (func $getPiece (param $x i32) (param $y i32) (result i32)
    (if (result i32)
      (block (result i32)
        (i32.and
          (call $inRange (i32.const 0) (i32.const 7) (get_local $x))
          (call $inRange (i32.const 0) (i32.const 7) (get_local $y))
        )
      )
      (then
        (i32.load (call $offsetForPosition (get_local $x) (get_local $y)))
      )
      (else
        (unreachable)
      )
    )
  )

  (func $inRange (param $min i32) (param $max i32) (param $value i32) (result i32)
    (i32.and
      (i32.ge_s (get_local $value) (get_local $min))
      (i32.le_s (get_local $value) (get_local $max))
    )
  )

  (func $isOccupied (param $x i32) (param $y i32) (result i32)
    (i32.gt_s (call $getPiece (get_local $x) (get_local $y)) (i32.const 0))
  )

  ;; Gets the current turn "owner" (white or black)
  (func $getTurnOwner (result i32)
    (get_global $currentTurn)
  )

  ;; Flip the turn owner from white to black or vice versa
  (func $toggleTurnOwner
    (if (i32.eq (call $getTurnOwner) (get_global $WHITE))
      (then (set_global $currentTurn (get_global $BLACK)))
      (else (set_global $currentTurn (get_global $WHITE)))
    )
  )

  ;; Set the current turn owner
  (func $setTurnOwner (param $owner i32)
    (set_global $currentTurn (get_local $owner))
  )

  ;; Determine if it's the player's turn
  (func $isPlayersTurn (param $player i32) (result i32)
    (i32.gt_s
      (i32.and (get_local $player) (call $getTurnOwner))
      (i32.const 0)
    )
  )

  ;; Should this piece get crowned?
  ;; Black pieces get crowned in row 0, white pieces in row 7
  (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
    (i32.or
      ;; Check for a black piece in row 0
      (i32.and
        (i32.eq (get_local $pieceY) (i32.const 0))
        (call $isBlack (get_local $piece))
      )
      ;; Check for a white piece in row 7
      (i32.and
        (i32.eq (get_local $pieceY) (i32.const 7))
        (call $isWhite (get_local $piece))
      )
    )
  )

  (func $crownPiece (param $x i32) (param $y i32)
    (local $piece i32)
    (local $crownedPiece i32)
    (set_local $piece (call $getPiece (get_local $x) (get_local $y)))
    (set_local $crownedPiece (call $withCrown (get_local $piece)))
    (call $setPiece (get_local $x) (get_local $y) (get_local $crownedPiece))
    (call $notifyPieceCrowned (get_local $x) (get_local $y))
  )

  (func $distance (param $x i32) (param $y i32) (result i32)
    (i32.sub (get_local $x) (get_local $y))
  )

  (func $isValidMove (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $player i32)
    (local $target i32)
    (set_local $player (call $getPiece (get_local $fromX) (get_local $fromY)))
    (set_local $target (call $getPiece (get_local $toX) (get_local $toY)))
    (if (result i32)
      (block (result i32)
        (i32.and
          (call $validJumpDistance (get_local $fromY) (get_local $toY))
          (i32.and
            (call $isPlayersTurn (get_local $player))
            (i32.eq (get_local $target) (i32.const 0)) ;; target must be unoccupied
          )
        )
      )
      (then (i32.const 1))
      (else (i32.const 0))
    )
  )

  ;; Ensure travel is 1 or 2 squares
  (func $validJumpDistance (param $from i32) (param $to i32) (result i32)
    (local $d i32)
    (set_local $d
      (if (result i32)
        (i32.gt_s (get_local $to) (get_local $from))
        (then (call $distance (get_local $to) (get_local $from)))
        (else (call $distance (get_local $from) (get_local $to)))
      )
    )
    (i32.le_u (get_local $d) (i32.const 2))
  )

  ;; Main move function to be called by the game host
  (func $move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (if (result i32)
      (block (result i32)
        (call $isValidMove (get_local $fromX) (get_local $fromY) (get_local $toX) (get_local $toY))
      )
      (then
        (call $doMove (get_local $fromX) (get_local $fromY) (get_local $toX) (get_local $toY))
      )
      (else (i32.const 0))
    )
  )

  (func $doMove (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $curPiece i32)
    (set_local $curPiece (call $getPiece (get_local $fromX) (get_local $fromY)))
    (call $toggleTurnOwner)
    (call $setPiece (get_local $toX) (get_local $toY) (get_local $curPiece))
    (call $setPiece (get_local $fromX) (get_local $fromY) (i32.const 0))
    (if (call $shouldCrown (get_local $toY) (get_local $curPiece))
      (then (call $crownPiece (get_local $toX) (get_local $toY))))
    (call $notifyPieceMoved (get_local $fromX) (get_local $fromY) (get_local $toX) (get_local $toY))
    (i32.const 1)
  )

  ;; Manually place each piece on the board to initialize the game
  (func $initBoard
    ;; Place the white pieces at the top of the board
    (call $setPiece (i32.const 1) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 3) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 5) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 7) (i32.const 0) (i32.const 2))

    (call $setPiece (i32.const 0) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 2) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 4) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 6) (i32.const 1) (i32.const 2))

    (call $setPiece (i32.const 1) (i32.const 2) (i32.const 2))
    (call $setPiece (i32.const 3) (i32.const 2) (i32.const 2))
    (call $setPiece (i32.const 5) (i32.const 2) (i32.const 2))
    (call $setPiece (i32.const 7) (i32.const 2) (i32.const 2))

    ;; Place the black pieces at the bottom of the board
    (call $setPiece (i32.const 0) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 2) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 4) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 6) (i32.const 5) (i32.const 1))

    (call $setPiece (i32.const 1) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 3) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 5) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 7) (i32.const 6) (i32.const 1))

    (call $setPiece (i32.const 0) (i32.const 7) (i32.const 1))
    (call $setPiece (i32.const 2) (i32.const 7) (i32.const 1))
    (call $setPiece (i32.const 4) (i32.const 7) (i32.const 1))
    (call $setPiece (i32.const 6) (i32.const 7) (i32.const 1))

    (call $setTurnOwner (i32.const 1)) ;; Black goes first
  )

  (export "indexForPosition" (func $indexForPosition))
  (export "offsetForPosition" (func $offsetForPosition))
  (export "isCrowned" (func $isCrowned))
  (export "isWhite" (func $isWhite))
  (export "isBlack" (func $isBlack))
  (export "withCrown" (func $withCrown))
  (export "withoutCrown" (func $withoutCrown))
  (export "setPiece" (func $setPiece))
  (export "getPiece" (func $getPiece))
  (export "isOccupied" (func $isOccupied))
  (export "getTurnOwner" (func $getTurnOwner))
  (export "toggleTurnOwner" (func $toggleTurnOwner))
  (export "setTurnOwner" (func $setTurnOwner))
  (export "isPlayersTurn" (func $isPlayersTurn))
  (export "shouldCrown" (func $shouldCrown))
  (export "crownPiece" (func $crownPiece))
  (export "isValidMove" (func $isValidMove))
  (export "move" (func $move))
  (export "initBoard" (func $initBoard))
)
