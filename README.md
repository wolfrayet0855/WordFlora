Overview

WordFlora is a SwiftUI-based word-guessing game where players try to uncover a hidden word by guessing individual letters. The game keeps track of the number of words guessed and missed, provides feedback through animations and sounds, and supports restarting or playing again with different words.

Features

Game State Tracking:

Tracks words guessed and missed. Keeps track of the current word, the revealed letters, and remaining guesses.

UI Components: Displays the number of words guessed and missed. Shows the number of words remaining and total words in the game. Provides a text field for letter input and buttons for guessing and restarting the game. Displays a changing image based on the number of remaining guesses, using flower images. Game Mechanics: The player guesses letters to reveal the hidden word. The game updates the displayed word with correct guesses and provides feedback on incorrect guesses. The game transitions between words and provides feedback when all guesses are used or a word is successfully guessed. Sound Effects: Plays sounds for correct guesses, incorrect guesses, and when a word is guessed. Code Summary

State Variables

wordsGuessed: Counts the number of words successfully guessed.

wordsMissed: Counts the number of words that were not guessed within the allowed attempts.

currentWordIndex: Keeps track of the index of the current word.

wordToGuess: The current word that the player needs to guess.

revealedWord: Shows the partially guessed word with underscores for unguessed letters.

lettersGuessed: Tracks all guessed letters.

guessesRemaining: Number of guesses remaining before the player runs out of attempts.

gameStatusMessage: Displays messages about the game status.

guessedLetter: The most recent letter guessed by the player.

imageName: The name of the image representing the current state of the flower, based on remaining guesses.

playAgainHidden: Controls the visibility of the "play again" button.

playingagainButtonLabel: Text label for the "play again" button.

audioPlayer: Manages audio playback for game sounds.

textFieldIsFocused: Manages focus state for the text field.

Functions guessALetter(): Updates the revealed word based on the guessed letter and tracks guessed letters.

updateGamePlay(): Updates the game state based on whether the guessed letter is correct or incorrect, adjusts the flower image, and manages game status messages.

playSound(soundName:): Plays the specified sound for game events.

Future Enhancements

Handling Deprecated Items: Update deprecated SwiftUI items to ensure compatibility with the latest iOS versions. 
