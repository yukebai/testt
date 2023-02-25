import SpriteKit

class GameScene: SKScene {
    
    //MARK: - Properties
    
    enum Difficulty {
        case beginner, intermediate, advanced
    }
    
    let difficulties: [Difficulty] = [.beginner, .intermediate, .advanced]
    
    var difficulty: Difficulty = .beginner {
        didSet {
            switch difficulty {
            case .beginner:
                numRows = 9
                numCols = 9
                numMines = 10
            case .intermediate:
                numRows = 16
                numCols = 16
                numMines = 40
            case .advanced:
                numRows = 16
                numCols = 30
                numMines = 99
            }
            grid = [[ButtonNode]](repeating: [ButtonNode](repeating: ButtonNode(), count: numCols), count: numRows)
            setupUI()
            setupGrid()
        }
    }
    
    var numRows = 9
    var numCols = 9
    var numMines = 10
    var grid = [[ButtonNode]]()
    var gameOver = false
    var didWin = false
    var remainingCells = 0
    var numFlags = 0
    var smileyButton = SKSpriteNode(imageNamed: "smiley_happy")
    var levelButton = SKSpriteNode(imageNamed: "level_button")
    var levelLabel = SKLabelNode(text: "Beginner")
    
    //MARK: - Lifecycle Methods
    
    override func didMove(to view: SKView) {
        difficulty = .beginner
    }
    
    //MARK: - Setup Methods
    
    func setupGrid() {
        for row in 0..<numRows {
            for col in 0..<numCols {
                let button = ButtonNode(imageNamed: "cell_hidden")
                button.position = CGPoint(x: col * 32 + 16, y: row * 32 + 96)
                button.row = row
                button.col = col
                addChild(button)
                grid[row][col] = button
            }
        }
        placeMines()
        calculateAdjacentMines()
    }
    
    func placeMines() {
        var numMinesToPlace = numMines
        while numMinesToPlace > 0 {
            let row = Int.random(in: 0..<numRows)
            let col = Int.random(in: 0..<numCols)
            if !grid[row][col].isMine {
                grid[row][col].isMine = true
                numMinesToPlace -= 1
            }
        }
    }
    
    func calculateAdjacentMines() {
        for row in 0..<numRows {
            for col in 0..<numCols {
                if grid[row][col].isMine {
                    continue
                }
                var count = 0
                for i in -1...1 {
                    for j in -1...1 {
                        let r = row + i
                        let c = col + j
                        if r < 0 || r >= numRows || c < 0 || c >= numCols || (i == 0 && j == 0) {
                            continue
                        }
                        if grid[r][c].isMine {
                            count += 1
                        }
                        
                    }
                }
                grid[row][col].numAdjacentMines = count
                remainingCells += 1
            }
        }
    }
    
    func setupUI() {
        backgroundColor = .white
        
        let topBar = SKSpriteNode(color: .gray, size: CGSize(width: size.width, height: 80))
        topBar.position = CGPoint(x: size.width / 2, y: size.height - 40)
        addChild(topBar)
        
        smileyButton.position = CGPoint(x: size.width / 2, y: size.height - 40)
        addChild(smileyButton)
        
        levelButton.position = CGPoint(x: 40, y: size.height - 40)
        addChild(levelButton)
        
        levelLabel.position = CGPoint(x: 100, y: size.height - 40)
        addChild(levelLabel)
    }
    
    //MARK: - Game Logic Methods
    
    func revealCell(_ button: ButtonNode) {
        if button.isMine {
            gameOver = true
            revealMines()
            smileyButton.texture = SKTexture(imageNamed: "smiley_sad")
            return
        }
        button.reveal()
        remainingCells -= 1
        if remainingCells == 0 {
            gameOver = true
            didWin = true
            smileyButton.texture = SKTexture(imageNamed: "smiley_win")
            return
        }
        if button.numAdjacentMines == 0 {
            revealAdjacentCells(row: button.row, col: button.col)
        }
    }
    
    func revealAdjacentCells(row: Int, col: Int) {
        for i in -1...1 {
            for j in -1...1 {
                let r = row + i
                let c = col + j
                if r < 0 || r >= numRows || c < 0 || c >= numCols || (i == 0 && j == 0) {
                    continue
                }
                let button = grid[r][c]
                if button.isRevealed {
                    continue
                }
                revealCell(button)
            }
        }
    }
    
    func revealMines() {
        for row in 0..<numRows {
            for col in 0..<numCols {
                let button = grid[row][col]
                if button.isMine {
                    button.texture = SKTexture(imageNamed: "cell_mine")
                }
            }
        }
    }
    
    func flagCell(_ button: ButtonNode) {
        if button.isFlagged {
            button.unflag()
            numFlags -= 1
        } else {
            button.flag()
            numFlags += 1
        }
    }
    
    func reset() {
        removeAllChildren()
        remainingCells = 0
        numFlags = 0
        gameOver = false
        didWin = false
        smileyButton.texture = SKTexture(imageNamed: "smiley_happy")
        levelLabel.text = "Beginner"
        difficulty = .beginner
    }
    
    //MARK: - Touch Handling Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        for node in nodes {
            if node == smileyButton {
                reset()
                return
            } else if node == levelButton {
                let index = difficulties.firstIndex(of: difficulty)!
                let nextIndex = (index + 1) % difficulties.count
                
                return
            } else if let button = node as? ButtonNode {
                if !gameOver {
                    if touch.tapCount == 1 {
                        revealCell(button)
                    } else if touch.tapCount == 2 {
                        flagCell(button)
                    }
                }
                return
            }
        }
    }
}


//MARK: - ButtonNode Class

class ButtonNode: SKSpriteNode {
let row: Int
let col: Int
var isMine = false
var isRevealed = false
var isFlagged = false
var numAdjacentMines = 0

    init(row: Int, col: Int, size: CGSize) {
        self.row = row
        self.col = col
        super.init(texture: SKTexture(imageNamed: "cell_hidden"), color: .clear, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reveal() {
        isRevealed = true
        texture = SKTexture(imageNamed: "cell_empty_\(numAdjacentMines)")
    }

    func flag() {
        isFlagged = true
        texture = SKTexture(imageNamed: "cell_flag")
    }

    func unflag() {
        isFlagged = false
        texture = SKTexture(imageNamed: "cell_hidden")
    }
}

//MARK: - Enums

enum Difficulty {
case beginner, intermediate, expert
    var numRows: Int {
        switch self {
        case .beginner:
            return 9
        case .intermediate:
            return 16
        case .expert:
            return 16
        }
    }

    var numCols: Int {
        switch self {
        case .beginner:
            return 9
        case .intermediate:
            return 16
        case .expert:
            return 30
        }
    }

    var numMines: Int {
        switch self {
        case .beginner:
            return 10
        case .intermediate:
            return 40
        case .expert:
            return 99
        }
    }
}

//MARK: - Extensions

extension SKLabelNode {
convenience init(text: String, fontSize: CGFloat, fontColor: SKColor, position: CGPoint) {
self.init(text: text)
self.fontSize = fontSize
self.fontColor = fontColor
self.position = position
}
}

extension SKTexture {
convenience init(imageNamed name: String, filteringMode: SKTextureFilteringMode = .nearest) {
self.init(imageNamed: name)
self.filteringMode = filteringMode
}
}
