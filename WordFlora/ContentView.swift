//
//  ContentView.swift
//  WordFlora
//
//  Created by user on 9/11/24.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    @State private var wordsGuessed = 0
    @State private var wordsMissed = 0
    @State private var currentWordIndex = 0
    @State private var wordToGuess = ""
    @State private var revealedWord = ""
    @State private var lettersGuessed = ""
    @State private var guessesRemaining = 8 // 8 due to petals on flower and imagecount in assest catalog
    @State private var gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
    @State private var guessedLetter = ""
    @State private var imageName = "flower8"
    @State private var playAgainHidden = true
    @State private var playingagainButtonLabel = "Another Word?"
    @State private var audioPlayer: AVAudioPlayer!
    @FocusState private var textFieldIsFocused: Bool

    @State private var wordsToGuess: [String] = [] // Words fetched from API
    private let maximumGuesses = 8

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed + wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)

            Spacer()
            Text(gameStatusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80)
                .minimumScaleFactor(0.5)
                .padding()

            Text(revealedWord)
                .font(.title)

            if playAgainHidden {
                HStack {
                    TextField("", text: $guessedLetter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter) { _ in
                            guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = guessedLetter.last else {
                                return
                            }
                            guessedLetter = String(lastChar).uppercased()
                        }
                        .onSubmit {
                            guard guessedLetter != "" else {
                                return
                            }
                            guessALetter()
                            updateGamePlay()
                        }
                        .focused($textFieldIsFocused)

                    Button("Guess a Letter") {
                        guessALetter()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            } else {
                Button(playingagainButtonLabel) {
                    if currentWordIndex == wordsToGuess.count {
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playingagainButtonLabel = "Another Word?"
                    }
                    if !wordsToGuess.isEmpty {
                        wordToGuess = wordsToGuess[currentWordIndex]
                        revealedWord = "_" + String(repeating: " _", count: wordToGuess.count - 1)
                        lettersGuessed = ""
                        guessesRemaining = maximumGuesses
                        imageName = "flower\(guessesRemaining)"
                        gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
                        playAgainHidden = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
            Spacer()

            Image(imageName)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: imageName)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            fetchWords()
        }
    }

    func fetchWords() {
        let urlString = "https://random-word-api.herokuapp.com/word?number=10"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching words: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                // Assume the response is a JSON array of strings
                let fetchedWords = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    wordsToGuess = fetchedWords.map { $0.uppercased() } // Convert words to uppercase
                    if !wordsToGuess.isEmpty {
                        wordToGuess = wordsToGuess[currentWordIndex]
                        revealedWord = "_" + String(repeating: " _", count: wordToGuess.count - 1)
                        guessesRemaining = maximumGuesses
                    }
                }
            } catch {
                print("Error decoding words: \(error)")
            }
        }.resume()
    }

    func guessALetter() {
        textFieldIsFocused = false
        lettersGuessed = lettersGuessed + guessedLetter

        revealedWord = ""
        for letter in wordToGuess {
            if lettersGuessed.contains(letter) {
                revealedWord = revealedWord + "\(letter) "
            } else {
                revealedWord = revealedWord + "_ "
            }
        }
        revealedWord.removeLast()
    }

    func updateGamePlay() {
        if !wordToGuess.contains(guessedLetter) {
            guessesRemaining -= 1
            imageName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                imageName = "flower\(guessesRemaining)"
            }
        } else {
            playSound(soundName: "correct")
        }

        if !revealedWord.contains("_") {
            gameStatusMessage = "You've Guessed it! It took you \(lettersGuessed.count) Guesses to guess the word."
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-guessed")
        } else if guessesRemaining == 0 {
            gameStatusMessage = "So Sorry. You're all out of guesses."
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-not-guessed")
        } else {
            gameStatusMessage = "You've Made \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es")"
        }

        if currentWordIndex == wordsToGuess.count {
            playingagainButtonLabel = "Restart Game?"
            gameStatusMessage = gameStatusMessage + "\nYou've tried all the words. Restart from the beginning?"
        }
        guessedLetter = ""
    }

    func playSound(soundName: String) {
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("😡 Could not read file named \(soundName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            print("😡 ERROR: \(error.localizedDescription) creating audioPlayer.")
        }
    }
}

#Preview {
    ContentView()
}
