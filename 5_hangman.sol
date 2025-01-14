// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hangman {
    address public owner;
    address public player;
    string[] private wordList = ["solidity", "blockchain", "ethereum", "contract", "webthree"];
    string private selectedWord;
    bytes32 private hashedWord;
    string public currentWordState;
    uint8 public maxAttempts;
    uint8 public attemptsLeft;
    bool public gameActive;

    mapping(string => bool) private guessedLetters;

    event GameStarted(address indexed player, string currentWordState);
    event LetterGuessed(address indexed player, string letter, bool correct);
    event GameWon(address indexed player);
    event GameLost(address indexed player);

    constructor() {
        owner = msg.sender;
        maxAttempts = 10;
    }

    modifier onlyPlayer() {
        require(msg.sender == player, "Not the current player");
        _;
    }

    modifier gameInProgress() {
        require(gameActive, "No active game");
        _;
    }

    // Helper function to check if a character is a valid alphabet letter
    function isAlphabet(string memory letter) internal pure returns (bool) {
        bytes memory b = bytes(letter);
        if (b.length != 1) return false;
        bytes1 char = b[0];
        return (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A); // A-Z or a-z
    }

    // Helper function to convert a character to lowercase
    function toLowerCase(string memory letter) internal pure returns (string memory) {
        bytes memory b = bytes(letter);
        if (b[0] >= 0x41 && b[0] <= 0x5A) { // If the character is uppercase A-Z
            b[0] = bytes1(uint8(b[0]) + 32); // Convert to lowercase
        }
        return string(b);
    }

    // Start a new game
    function startGame() external {
        require(!gameActive, "Game already in progress");

        // Select a random word
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % wordList.length;
        selectedWord = wordList[randomIndex];
        hashedWord = keccak256(abi.encodePacked(selectedWord));

        // Initialize game state
        player = msg.sender;
        gameActive = true;
        attemptsLeft = maxAttempts;

        // Clear guessed letters
        for (uint256 i = 0; i < 26; i++) {
            guessedLetters[string(abi.encodePacked(bytes1(uint8(97 + i))))] = false;
        }

        // Create the initial word state (e.g., "_ _ _ _ _ _ _")
        bytes memory initialWordState = new bytes(bytes(selectedWord).length);
        for (uint256 i = 0; i < bytes(selectedWord).length; i++) {
            initialWordState[i] = "_";
        }
        currentWordState = string(initialWordState);

        emit GameStarted(player, currentWordState);
    }

    // Guess a letter
    function guessLetter(string memory letter) external onlyPlayer gameInProgress {
        require(isAlphabet(letter), "Invalid letter: must be A-Z or a-z");

        letter = toLowerCase(letter); // Convert to lowercase
        require(!guessedLetters[letter], "Letter already guessed");

        guessedLetters[letter] = true;
        bytes memory wordBytes = bytes(selectedWord);
        bytes memory stateBytes = bytes(currentWordState);
        bool correctGuess = false;

        for (uint256 i = 0; i < wordBytes.length; i++) {
            if (wordBytes[i] == bytes(letter)[0]) {
                stateBytes[i] = wordBytes[i];
                correctGuess = true;
            }
        }

        currentWordState = string(stateBytes);

        if (!correctGuess) {
            attemptsLeft--;
        }

        emit LetterGuessed(player, letter, correctGuess);

        if (keccak256(abi.encodePacked(currentWordState)) == hashedWord) {
            gameActive = false;
            emit GameWon(player);
        } else if (attemptsLeft == 0) {
            gameActive = false;
            emit GameLost(player);
        }
    }

    // View the selected word (for debugging, remove in production!)
    function revealWord() external view returns (string memory) {
        require(msg.sender == owner, "Only owner can reveal the word");
        return selectedWord;
    }
}
