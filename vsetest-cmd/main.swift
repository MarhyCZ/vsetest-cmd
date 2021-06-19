//
//  main.swift
//  vsetest-cmd
//
//  Created by Michal Marhan on 17.06.2021.
//

import Foundation

struct Answer: Hashable {
    let text: String
    let isCorrect: Bool
}

struct Question: Hashable {
    let title: String
    let answers:[Answer]
    let correctStreak: Int? = nil
    
}

// fresh means not yet played
struct QuestionSet {
    var fresh = Set<Question>()
    var correct = Set<Question>()
    var mistaken = Set<Question>()
    
    var freshCount: Int {
        return fresh.count
    }
    var mistakeCount: Int {
        return mistaken.count
    }
    var correctCount: Int {
        return correct.count
    }
    var remainingCount: Int {
        return mistaken.count + fresh.count
    }
    var questionCount: Int {
        return fresh.count + correct.count + mistaken.count
    }
}

func loadQuestionsFile() throws -> [Question] {
    let fileURL = URL.init(fileURLWithPath: "/Users/michal/Downloads/Pravo 2014 - UTF.txt")
    
    let fileContents = try String(contentsOf: fileURL)
    let textLines = fileContents.components(separatedBy: .newlines)
    return parseQuestions(with: textLines)
    
    //    let handle = FileHandle.standardInput
    //    for try await line in handle.bytes.lines {
    //        print(line)
    //    }
}

func parseQuestions(with textLines: [String]) -> [Question] {
    var questions = [Question]()
    var currQuestion = ""
    var currAnswers = [Answer]()
    
    textLines.forEach { line in
        if (line.isEmpty) {return}
        // If question ended (new question title detected), create new one
        let shouldEndQuestion = !(line.first == "+" || line.first == "-")
        if (shouldEndQuestion) {
            questions.append(Question(title: currQuestion, answers: currAnswers))
            currAnswers.removeAll()
            currQuestion = line
        } else {
            var strippedLine = line
            let isCorrect = strippedLine.removeFirst() == "+"
            // Remove spaces at the beginning
            strippedLine = strippedLine.trimmingCharacters(in: .whitespaces)
            currAnswers.append(Answer(text: strippedLine, isCorrect: isCorrect))
        }
    }
    questions.append(Question(title: currQuestion, answers: currAnswers)) // Add last question
    questions.removeFirst() // First is empty
    return questions
}

class Quiz {
    private var questions: QuestionSet
    private var currentQuestion: Question
    // Number of questions before trying one of the mistaken
    private var nextTry: Int?
    // Evidovat chyby
    // Chybna odpoved bude potrebovat 3x rict spravne otazku
    // bude potreba chybne otazky nejakou random logikou ukazovat drive
    // Zamichat odpovedi
    init(using questions: [Question]) {
        self.nextTry = nil
        self.questions = QuestionSet()
        self.questions.fresh = Set(questions)
        self.currentQuestion = Question(title: "", answers: [Answer]())
        start()
    }
    func start() {
        repeat {
            pickQuestion()
            print(currentQuestion.title)
            print("____________________________")
            self.currentQuestion.answers.forEach { answer in
                print(answer.text + "\n")
            }
            if let typed = readLine(strippingNewline: true) {
                let guessNumbers = typed.split(separator: " ").map{ Int(String($0)) ?? 0 }
                let guesses = IndexSet(guessNumbers.sorted()).map {self.currentQuestion.answers[$0]}
                let answer = answerQuestion(using: guesses )
                print(answer)
                moveQuestion(when: answer)
                print("Fresh questions: \(questions.freshCount)")
                print("Correct questions: \(questions.correctCount)")
                print("Mistaken questions: \(questions.mistakeCount)")
            }
        } while self.questions.remainingCount > 0
    }
    
    private func pickQuestion() {
        guard var nextTry = self.nextTry else {
            return self.currentQuestion = self.questions.fresh.randomElement()!
        }
        if (nextTry == 0 || questions.freshCount == 0) {
            nextTry = Int.random(in: 5...10)
            return self.currentQuestion = self.questions.mistaken.randomElement()!
        } else {
            nextTry -= 1
            return self.currentQuestion = self.questions.fresh.randomElement()!
        }
    }
    
    private func moveQuestion(when isCorrect: Bool) {
        if(isCorrect) {
            self.questions.fresh.remove(self.currentQuestion)
            self.questions.mistaken.remove(self.currentQuestion)
            self.questions.correct.insert(self.currentQuestion)
        } else {
            self.questions.fresh.remove(self.currentQuestion)
            self.questions.mistaken.insert(self.currentQuestion)
        }
    }
    
    func answerQuestion(using answers:[Answer]) -> Bool {
        let correctAnswers = Set(currentQuestion.answers.filter {$0.isCorrect})
        return Set(answers) == correctAnswers
    }
    
    func hasEnded() -> Bool {
        return questions.remainingCount == 0
    }
    // If nextTry == 0 then select from mistakes and generate rand number to nextry
    // else select another from array
}

//print(cislo)
if let questions = try? loadQuestionsFile() {
    let quiz = Quiz(using: questions)
}
let cislo = readLine(strippingNewline: true)
