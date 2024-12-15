// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Minesweeper {
    struct Board {
        uint8 rows;
        uint8 cols;
        uint8[][] grid;
        bool[][] revealed;
        bool isGameActive;
        uint256 mines;
        uint256 revealedCount;
    }

    // Tablero único para un jugador (ampliaremos esto para multijugador después)
    Board public playerBoard;

    // Evento para rastrear movimientos
    event CellRevealed(uint8 row, uint8 col, uint8 value);

    // Evento para mostrar mensajes
    event GameMessage(address player, string message);

    // Modificador para asegurarnos de que el juego esté activo
    modifier gameIsActive() {
        require(playerBoard.isGameActive, unicode"El juego no está activo.");
        _;
    }

    // Inicializar un nuevo juego
    function initializeGame(uint8 _rows, uint8 _cols, uint256 _mines) public {
        require(_rows > 0 && _cols > 0, unicode"Tamaño de tablero inválido.");
        require(_mines > 0 && _mines < _rows * _cols, unicode"Número de minas inválido.");

        // Limpiar el tablero existente
        delete playerBoard;

        // Crear un nuevo tablero
        playerBoard.rows = _rows;
        playerBoard.cols = _cols;
        playerBoard.mines = _mines;
        playerBoard.isGameActive = true;
        playerBoard.revealedCount = 0;

        // Inicializar el tablero y la matriz de revelados
        for (uint8 i = 0; i < _rows; i++) {
            uint8[] memory row = new uint8[](_cols);
            bool[] memory revealedRow = new bool[](_cols);
            playerBoard.grid.push(row);
            playerBoard.revealed.push(revealedRow);
        }

        // Colocar minas de forma aleatoria
        uint256 minesPlaced = 0;
        while (minesPlaced < _mines) {
            uint8 randomRow =
                uint8(uint256(keccak256(abi.encodePacked(block.timestamp, minesPlaced, msg.sender))) % _rows);
            uint8 randomCol =
                uint8(uint256(keccak256(abi.encodePacked(block.timestamp, minesPlaced + 1, msg.sender))) % _cols);

            // Solo colocar la mina si la casilla está vacía
            if (playerBoard.grid[randomRow][randomCol] != 1) {
                playerBoard.grid[randomRow][randomCol] = 1;
                minesPlaced++;
            }
        }

        emit GameMessage(msg.sender, unicode"Nuevo juego inicializado correctamente.");
    }

    // Realizar un movimiento
    function revealCell(uint8 _row, uint8 _col) public gameIsActive {
        require(_row < playerBoard.rows && _col < playerBoard.cols, unicode"Coordenadas fuera de rango.");
        require(!playerBoard.revealed[_row][_col], unicode"Casilla ya revelada.");

        playerBoard.revealed[_row][_col] = true;
        playerBoard.revealedCount++;

        // Si es una mina, el jugador pierde
        if (playerBoard.grid[_row][_col] == 1) {
            playerBoard.isGameActive = false;
            emit GameMessage(msg.sender, unicode"¡Boom! Has perdido: descubriste una mina.");
            emit CellRevealed(_row, _col, 9); // 9 representa una mina
            return;
        }

        // Emitir el evento con el número de minas alrededor
        uint8 minesAround = countMinesAround(_row, _col);
        emit CellRevealed(_row, _col, minesAround);

        // Emitir mensaje de éxito si no hay mina
        emit GameMessage(msg.sender, unicode"Movimiento satisfactorio, no hay mina aquí.");

        // Si todas las casillas no-minas están reveladas, el jugador gana
        if (playerBoard.revealedCount == (playerBoard.rows * playerBoard.cols) - playerBoard.mines) {
            playerBoard.isGameActive = false;
            emit GameMessage(msg.sender, unicode"¡Felicidades! Has ganado el juego.");
        }
    }

    // Contar minas alrededor de una casilla
    function countMinesAround(uint8 _row, uint8 _col) internal view returns (uint8) {
        uint8 count = 0;
        for (int8 i = -1; i <= 1; i++) {
            for (int8 j = -1; j <= 1; j++) {
                int8 newRow = int8(_row) + i;
                int8 newCol = int8(_col) + j;
                if (newRow >= 0 && newRow < int8(playerBoard.rows) && newCol >= 0 && newCol < int8(playerBoard.cols)) {
                    if (playerBoard.grid[uint8(newRow)][uint8(newCol)] == 1) {
                        count++;
                    }
                }
            }
        }
        return count;
    }

    // Consultar el estado de una casilla
    function getCellState(uint8 _row, uint8 _col) public view returns (bool, uint8) {
        require(_row < playerBoard.rows && _col < playerBoard.cols, unicode"Coordenadas fuera de rango.");
        return (playerBoard.revealed[_row][_col], playerBoard.grid[_row][_col]);
    }
}
