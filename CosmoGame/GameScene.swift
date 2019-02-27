//
//  GameScene.swift
//  CosmoGame
//
//  Created by Andrew on 24/02/2019.
//  Copyright © 2019 Andrew. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let spaceShipCategory: UInt32 = 0x1 << 0
    let asteroidCategory: UInt32 = 0x1 << 1
    
    // 1 создаем экземпляр node
    var spaceShip: SKSpriteNode!
    var score = 0
    var scoreLabel: SKLabelNode!
    var spaceBackground: SKSpriteNode!
    var asteroidLayer: SKNode!
    var gameIsPaused: Bool = false
    var starsLayer: SKNode!
    var spaceShipLayer: SKNode!
    var musicPlayer: AVAudioPlayer!
    
    // метод для включения паузы
    func pauseTheGame() {
        gameIsPaused = true
        self.asteroidLayer.isPaused = true
        physicsWorld.speed = 0
        starsLayer.isPaused = true
        musicPlayer.pause()
    }
    
    // метод для снятия с паузы
    func unpauseTheGame() {
        gameIsPaused = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
        starsLayer.isPaused = false
        musicPlayer.play()
    }
    
//    func pauseButtonPressed(sender: AnyObject) {
//        if !gameIsPaused {
//            pauseTheGame()
//        } else {
//            unpauseTheGame()
//        }
//    }
    
    // метод который вызывает резет
    func resetTheGame(){
        score = 0
        scoreLabel.text = "Score: \(score)"
        gameIsPaused = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -0.8)
        
        scene?.size = UIScreen.main.bounds.size
        
        let width = UIScreen.main.bounds.width * 2
        let height = UIScreen.main.bounds.width * 2
        
        // создаем бэкраунд
        spaceBackground = SKSpriteNode(imageNamed: "spaceBackgroundImg3")
        spaceBackground.size = CGSize(width: width + 50, height: height + 50)
        addChild(spaceBackground)
        
        // stars из эммиттера Stars.sks - это наш класс со звездами
        let starPath = Bundle.main.path(forResource: "Stars", ofType: "sks")
        let starsEmitter = NSKeyedUnarchiver.unarchiveObject(withFile: starPath!) as? SKEmitterNode
        
        starsEmitter?.zPosition = 1
        starsEmitter?.position = CGPoint(x: frame.midX, y: frame.height / 2)
        starsEmitter?.particlePositionRange.dx = frame.width
        starsEmitter?.advanceSimulationTime(10)
        starsLayer = SKNode()
        starsEmitter?.zPosition = 1
        addChild(starsLayer)
        
        starsLayer.addChild(starsEmitter!)
        
        
        // инициализируем космический корабль и зааем ему физическое тело
        spaceShip = SKSpriteNode(imageNamed: "spaceShipPic")
        spaceShip.xScale = 0.3
        spaceShip.yScale = 0.3
        
        spaceShip.physicsBody = SKPhysicsBody(texture: spaceShip.texture!, size: spaceShip.size)
        spaceShip.physicsBody?.isDynamic = false
        spaceShip.physicsBody?.categoryBitMask = spaceShipCategory
        spaceShip.physicsBody?.collisionBitMask = asteroidCategory
        spaceShip.physicsBody?.contactTestBitMask = asteroidCategory
        
        // мерцает цветом корабль
        let colorAction1 = SKAction.colorize(with: .yellow, colorBlendFactor: 1, duration: 1)
        let colorAction2 = SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 1)
        let colorSequenceAnimation = SKAction.sequence([colorAction1, colorAction2])
        let colorActionRepeat = SKAction.repeatForever(colorSequenceAnimation)
        
        
        
        spaceShip.run(colorActionRepeat)
        
        //addChild(spaceShip)
        // create Layer of Space Ship
        spaceShipLayer = SKNode()
        spaceShipLayer.addChild(spaceShip)
        spaceShipLayer.zPosition = 3
        spaceShipLayer.position = CGPoint(x: frame.midX, y: frame.height / 4)
        addChild(spaceShipLayer)
        
        //create fire
        let firePath = Bundle.main.path(forResource: "Fire", ofType: "sks")
        let fireEmitter = NSKeyedUnarchiver.unarchiveObject(withFile: firePath!) as? SKEmitterNode
        fireEmitter?.zPosition = 0
        fireEmitter?.position.y = -40
        fireEmitter?.targetNode = self
        spaceShipLayer.addChild(fireEmitter!)

        
        asteroidLayer = SKNode()
        asteroidLayer.zPosition = 2
        addChild(asteroidLayer)
        
        //генерируем астероиды
        let asteroidCreate = SKAction.run {
            let asteroid  = self.createAsteroid()
            self.asteroidLayer.addChild(asteroid)
            asteroid.zPosition = 2
        }
        
        let asteroidPerSecond: Double = 2
        let asteroidCreationDelay = SKAction.wait(forDuration: 1.0 / asteroidPerSecond, withRange: 0.5)
        let asteroidSequenceAction = SKAction.sequence([asteroidCreate, asteroidCreationDelay])
        let asteroidRunAction = SKAction.repeatForever(asteroidSequenceAction)
        
        self.asteroidLayer.run(asteroidRunAction)
        
        scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.position = CGPoint(x: frame.size.width / scoreLabel.frame.size.width, y: 300)
//      scoreLabel.position = CGPoint(x: frame.size.width / scoreLabel.frame.size.width, y: frame.size.height - scoreLabel.calculateAccumulatedFrame().height - 15)
        
        addChild(scoreLabel)
        
        spaceBackground.zPosition = 0
        //spaceShip.zPosition = 1
        scoreLabel.zPosition = 3
        playMusic()
        
    }
    
    func playMusic(){
        if let musicPath = Bundle.main.url(forResource: "starSong", withExtension: "mp3"){
            musicPlayer = try! AVAudioPlayer(contentsOf: musicPath, fileTypeHint: nil)
            musicPlayer.play()
        }
        musicPlayer.numberOfLoops = -1
        musicPlayer.volume = 0.2
    }
    
    // функция для перемещения космического корабля
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameIsPaused{
        if let touch = touches.first{
            // 3 определяем точку прикосновения
            let touchLocation = touch.location(in: self)
            // определяем дистанцию
            let distance = distanceCalculate(a: spaceShip.position, b: touchLocation)
            let speed: CGFloat = 500
            let time = timeToTravelDistance(distance: distance, speed: speed)
            let moveAciton = SKAction.move(to: touchLocation, duration: time)
            moveAciton.timingMode = SKActionTimingMode.easeInEaseOut
            
            spaceShipLayer.run(moveAciton)
            
            let bgMoveAction = SKAction.move(to: CGPoint(x: -touchLocation.x / 100, y: -touchLocation.y / 100), duration: time)
            
            spaceBackground.run(bgMoveAction)
            
//            self.asteroidLayer.isPaused = !self.asteroidLayer.isPaused
//            physicsWorld.speed = 0
//            pauseTheGame()
            }
        }
    }
    
    // функция для расчета дистанции между точками а и б
    func distanceCalculate(a: CGPoint, b: CGPoint) -> CGFloat {
        return sqrt((b.x - a.x)*(b.x - a.x) + (b.y - a.y)*(b.y - a.y))
    }
    
    // функция для расчета времени перемещения
    func timeToTravelDistance(distance: CGFloat, speed: CGFloat) -> TimeInterval {
        let time = distance / speed
        return TimeInterval(time)
    }
    
    
    // создаем астероид на рандомной позиции
    func createAsteroid() -> SKSpriteNode {
        let asteroid = SKSpriteNode(imageNamed: "asteroidImg")
        
        let randomScale = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 6)) / 10
        
        asteroid.xScale = randomScale
        asteroid.yScale = randomScale
//        asteroid.position.x = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: Int(frame.size.height)))
        asteroid.position.x = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 6))
        asteroid.position.y = frame.size.height + asteroid.size.height
        asteroid.physicsBody = SKPhysicsBody(texture: asteroid.texture!, size: asteroid.size)
        asteroid.name = "asteroid"
        
        // обрабатываем столкновения
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.collisionBitMask = spaceShipCategory | asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = spaceShipCategory
        
        // угловая скорость углового вектора
        let asteroidSpeedX: CGFloat = 100.0
        asteroid.physicsBody?.angularVelocity = CGFloat(drand48() * 2 - 1) * 3
        asteroid.physicsBody?.velocity.dx = CGFloat(drand48() * 2 - 1) * asteroidSpeedX
        
        return asteroid
    }
    
    //
    override func update(_ currentTime: TimeInterval) {
//        let asteroid = createAsteroid()
//        addChild(asteroid)
    }
    
    override func didSimulatePhysics() {
        // слой если у тебя будут дети с таким именем как астероид
        asteroidLayer.enumerateChildNodes(withName: "asteroid"){(asteroid, stop) in
            let heightScreen = UIScreen.main.bounds.height
            if asteroid.position.y < -heightScreen {
                asteroid.removeFromParent()
                
                self.score = self.score + 1
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == spaceShipCategory && contact.bodyB.categoryBitMask == asteroidCategory || contact.bodyB.categoryBitMask == spaceShipCategory && contact.bodyA.categoryBitMask == asteroidCategory {
            
            self.score = 0
            self.scoreLabel.text = "Score: \(self.score)"
        }
        
        let hitSountAction = SKAction.playSoundFileNamed("pew", waitForCompletion: true)
        run(hitSountAction)
        
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
    }
}
