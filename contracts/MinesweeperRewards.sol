// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMinesweeper {
    function getPlayerGameState()
        external
        view
        returns (bool isGameActive, uint256 revealedCount, uint256 totalCells, uint256 mines);
}

contract MinesweeperRewards is Ownable {
    // Dirección del contrato de Minesweeper
    address public minesweeperAddress;

    // Token ERC20 para recompensas
    IERC20 public rewardToken;

    // Mapeo para rastrear jugadores que ya reclamaron recompensa
    mapping(address => bool) public hasClaimedReward;

    // Cantidad de tokens como recompensa
    uint256 public rewardAmount;

    // Evento para registrar reclamos de recompensa
    event RewardClaimed(address indexed player, uint256 amount);
    // Evento para registrar cambios en la cantidad de recompensa
    event RewardAmountUpdated(uint256 newAmount);

    constructor(
        address _minesweeperAddress, 
        address _rewardTokenAddress, 
        uint256 _rewardAmount
    ) Ownable(msg.sender) {
        require(_minesweeperAddress != address(0), "Direccion de Minesweeper invalida");
        require(_rewardTokenAddress != address(0), "Direccion de Token invalida");
        require(_rewardAmount > 0, "La recompensa debe ser mayor a cero");

        minesweeperAddress = _minesweeperAddress;
        rewardToken = IERC20(_rewardTokenAddress);
        rewardAmount = _rewardAmount;
    }

    // Función para reclamar recompensa
    function claimReward() external {
        require(!hasClaimedReward[msg.sender], "Recompensa ya reclamada");

        // Verificar el estado del juego en el contrato Minesweeper
        IMinesweeper minesweeper = IMinesweeper(minesweeperAddress);
        (bool isGameActive, uint256 revealedCount, uint256 totalCells, uint256 mines) = minesweeper.getPlayerGameState();

        require(!isGameActive, "El juego aun esta activo");
        require(revealedCount == (totalCells - mines), "No se completaron todas las casillas");

        // Marcar que el jugador ha reclamado su recompensa
        hasClaimedReward[msg.sender] = true;

        // Transferir tokens como recompensa
        require(rewardToken.transfer(msg.sender, rewardAmount), "Error al transferir tokens");

        // Emitir evento de recompensa
        emit RewardClaimed(msg.sender, rewardAmount);
    }

    // Función para actualizar la cantidad de recompensa (solo el propietario)
    function updateRewardAmount(uint256 _newRewardAmount) external onlyOwner {
        require(_newRewardAmount > 0, "La recompensa debe ser mayor a cero");
        rewardAmount = _newRewardAmount;
        
        // Emitir evento de actualización de recompensa
        emit RewardAmountUpdated(_newRewardAmount);
    }

    // Función para retirar tokens en caso de emergencia (solo el propietario)
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(rewardToken.transfer(owner(), amount), "Error al transferir tokens");
    }
}