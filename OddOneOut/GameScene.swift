//
//  GameScene.swift
//  DiveIntoSpriteKit
//
//  Created by Paul Hudson on 16/10/2017.
//  Copyright © 2017 Paul Hudson. All rights reserved.
//

import SpriteKit

@objcMembers
class GameScene: SKScene {
    
    var level = 1
    
    var score = 0 {
        didSet {
            scoreLabel.attributedText = NSAttributedString(string: "SCORE: \(score)", attributes: whiteLabelAttributes)
        }
    }
    
    var startTime = 0.0
    var timeLabel = SKLabelNode(attributedText: NSAttributedString(string: ""))
    var isGameRunning = true
    
    let whiteLabelAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.white]
    let redLabelAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.systemRed]
    let scoreLabel = SKLabelNode(attributedText: NSAttributedString(string: ""))
    
    var sideXOffset: CGFloat = 70
    var sideYOffset: CGFloat = 30
    
    var horizontalSpacing: CGFloat = 0
    var verticalSpacing: CGFloat = 0
    
    lazy var rows: Int = {
        guard let scene = scene else { return 0 }
        guard let sceneHeight = scene.view?.bounds.height else { return 0 }
        let gridHeight = sceneHeight - 2.5 * sideYOffset
        let rows = Int(gridHeight / (itemWidthHeight + genericSpacing))
        verticalSpacing = (gridHeight - CGFloat(rows) * itemWidthHeight) / CGFloat(rows - 1)
        return rows
    }()
    lazy var cols: Int = {
        guard let scene = scene else { return 0 }
        guard let sceneWidth = scene.view?.bounds.width else { return 0 }
        let gridWidth = sceneWidth - 2.5 * sideXOffset
        let cols = Int(gridWidth / (itemWidthHeight + genericSpacing))
        horizontalSpacing = (gridWidth - CGFloat(cols) * itemWidthHeight) / CGFloat(cols - 1)
        return cols
    }()
    
    var itemWidthHeight: CGFloat = 45
    var itemSize: CGSize {
        return CGSize(width: itemWidthHeight, height: itemWidthHeight)
    }
    
    var genericSpacing: CGFloat = 20
    
    var sceneWidthByTwo: CGFloat {
        guard let scene = scene else { return 0 }
        guard let sceneWidth = scene.view?.bounds.width else { return 0 }
        return sceneWidth / 2.0
    }
    
    var sceneHeightByTwo: CGFloat {
        guard let scene = scene else { return 0 }
        guard let sceneHeight = scene.view?.bounds.height else { return 0 }
        return sceneHeight / 2.0
    }
    
    override func didMove(to view: SKView) {
        scene?.size = view.bounds.size
        scene?.scaleMode = .aspectFill
        
        let background = SKSpriteNode(imageNamed: "background-leaves")
        background.name = "background"
        background.zPosition = -1
        addChild(background)
        
        createGrid()
        createLevel()
        
        scoreLabel.position = CGPoint(x: sideXOffset - sceneWidthByTwo, y: sceneHeightByTwo - sideYOffset)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = 1
        background.addChild(scoreLabel)
        
        timeLabel.position = CGPoint(x: sceneWidthByTwo - sideXOffset, y: sceneHeightByTwo - sideYOffset)
        timeLabel.horizontalAlignmentMode = .right
        timeLabel.zPosition = 1
        background.addChild(timeLabel)
        
        let music = SKAudioNode(fileNamed: "night-cave")
        background.addChild(music)
        
        score = 0
    }
    
    func createGrid() {
        let xOffset = sideXOffset * 1.25 - sceneWidthByTwo
        let yOffset = sideYOffset * 1.25 - sceneHeightByTwo
        
        for row in 0 ..< rows {
            for col in 0 ..< cols {
                let item = SKSpriteNode(imageNamed: "elephant")
                item.scale(to: itemSize)
                item.alpha = 0
                item.position = CGPoint(x: xOffset + (CGFloat(col) * (itemSize.width + horizontalSpacing)), y: yOffset + (CGFloat(row) * (itemSize.height + verticalSpacing)))
                addChild(item)
            }
        }
    }
    
    func createLevel() {
        var itemsToShow = 5 + (level * 4)
        itemsToShow = min(itemsToShow, rows*cols)
        let items = children.filter { $0.name != "background" }

        let shuffled = items.shuffled() as! [SKSpriteNode]

        for item in shuffled {
            item.alpha = 0
        }

        let animals = ["elephant", "giraffe", "hippo", "monkey", "panda", "parrot", "penguin", "pig", "rabbit", "snake"]
        var shuffledAnimals = animals.shuffled()

        let correct = shuffledAnimals.removeLast()
        
        var showAnimals = [String]()
        var placingAnimal = 0
        var numUsed = 0

        for _ in 1 ..< itemsToShow {
            numUsed += 1

            showAnimals.append(shuffledAnimals[placingAnimal])

            if numUsed == 2 {
                numUsed = 0
                placingAnimal += 1
            }

            if placingAnimal == shuffledAnimals.count {
                placingAnimal = 0
            }
        }
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        for (index, animal) in showAnimals.enumerated() {
            let item = shuffled[index]

            item.texture = SKTexture(imageNamed: animal)
            item.scale(to: itemSize)
            item.run(fadeIn)

            item.name = "wrong"
        }
        
        shuffled.last?.texture = SKTexture(imageNamed: correct)
        shuffled.last?.scale(to: itemSize)
        shuffled.last?.run(fadeIn)
        shuffled.last?.name = "correct"
        
        isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGameRunning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        guard let tapped = tappedNodes.first else { return }
        if tapped.name == "correct" {
            correctAnswer(node: tapped)
        }
        else if tapped.name == "wrong" {
            wrongAnswer(node: tapped)
        }
    }
    
    func correctAnswer(node: SKNode) {
        isUserInteractionEnabled = false
        run(SKAction.playSoundFileNamed("correct-3", waitForCompletion: false))
        score += 1
        let fade = SKAction.fadeOut(withDuration: 0.5)
        
        for child in children {
            guard child.name == "wrong" else { continue }
            child.run(fade)
        }
        
        let scaleUp = SKAction.scale(by: 2, duration: 0.5)
        let scaleDown = SKAction.scale(by: 1, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        node.run(sequence)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.level < 5 {
                self.level += 1
            }
            self.createLevel()
        }
        
    }
    
    func wrongAnswer(node: SKNode) {
        run(SKAction.playSoundFileNamed("wrong-2", waitForCompletion: false))
        if score > 0 {
            score -= 1
        }
        let wrong = SKSpriteNode(imageNamed: "wrong")
        wrong.position = node.position
        wrong.zPosition = 5
        addChild(wrong)
        
        let wait = SKAction.wait(forDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([wait, remove])
        wrong.run(sequence)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
    }

    override func update(_ currentTime: TimeInterval) {
        if isGameRunning {
            if startTime == 0 {
                startTime = currentTime
            }
            let timePassed = currentTime - startTime
            let remainingTime = Int(ceil(120 - timePassed))
            
            if remainingTime > 15 {
                timeLabel.attributedText = NSAttributedString(string: "TIME: \(remainingTime)", attributes: whiteLabelAttributes)
            }
            else {
                timeLabel.attributedText = NSAttributedString(string: "TIME: \(remainingTime)", attributes: redLabelAttributes)
            }
            
            if remainingTime <= 0 {
                isUserInteractionEnabled = false
                isGameRunning = false
                
                let gameOver = SKSpriteNode(imageNamed: "gameOver1")
                gameOver.zPosition = 100
                
                let aspectRatio: CGFloat = 1.23
                gameOver.scale(to: CGSize(width: sceneWidthByTwo, height: sceneWidthByTwo / aspectRatio))
                
                addChild(gameOver)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if let scene = GameScene(fileNamed: "GameScene") {
                        scene.scaleMode = .aspectFill
                        self.view?.presentScene(scene)
                    }
                }
            }
        }
        else {
            timeLabel.alpha = 0
        }
    }
}

