Class {
	#name : #DependencyGraph,
	#superclass : #Object,
	#instVars : [
		'root',
		'flowGraph'
	],
	#category : #FlutterDependenciesPackager
}

{ #category : #initialization }
DependencyGraph >> buildGraphFrom: aFlutterPackage withData: aDictionnary [

	| currentNode nodesDico linksDico namesDico |
	"flowGraph := MeFlowchartDiagram new"
	self flowGraph direction: MeFCDirection LR.
	self flowGraph definitions isEmpty ifTrue: [ root := aFlutterPackage ].
	"Dictionnary for the nodes"
	nodesDico := Dictionary new.
	"Dictionnary for the links "
	linksDico := Dictionary new.
	"this last dictionnary is necessary to attribut a name to the node that is valid in mermaid"
	namesDico := Dictionary new.

	aDictionnary do: [ :each | 
		currentNode := MeFCNode named: (self createMermaidId: each name).
		currentNode text: each exportPackageName.
		nodesDico
			at: (self createMermaidId: each name)
			ifAbsentPut: [ currentNode ] ].

	nodesDico do: [ :n | flowGraph addDefinition: n ].

	aDictionnary do: [ :each | 
		currentNode := nodesDico at: (self createMermaidId: each name).

		each childrenDep do: [ :dep | 
			| link toNode |
			toNode := nodesDico at: (self createMermaidId: dep name).

			link := MeFCLink newFromNode: currentNode toNode: toNode.
			link toArrowType: MeFCArrowHeadType new.
			linksDico
				at: (self createMermaidId: currentNode name , toNode name)
				ifAbsentPut: [ link ] ] ].


	linksDico do: [ :n | flowGraph addDefinition: n ].

	^ self
]

{ #category : #initialization }
DependencyGraph >> createMermaidId: aString [

	^ aString replaceAllRegex: '_|\.' with: ''
]

{ #category : #initialization }
DependencyGraph >> flowGraph [

	^ flowGraph
]

{ #category : #initialization }
DependencyGraph >> initialize [

	root := FlutterPackage new.
	flowGraph := MeFlowchartDiagram new
]

{ #category : #initialization }
DependencyGraph >> visitFromLeaves: aDictionnary [

	"recursion start here"

	self
		deprecated: 'Use #FlutterDependenciesPackages instead'
		on: '16 February 2023'
		in:
		'Pharo-10.0.0+build.528.sha.296f1d3342e7e4ade13d9fc8179531388d9e62e3 (64 Bit)'.

	self visitFromLeaves: aDictionnary withBlock: [ :aPkg |  ]
]

{ #category : #initialization }
DependencyGraph >> visitFromLeaves: aDictionnary withBlock: aBlock [

	"recursion start here"

	| nextLeaves leaves |
	
		self
		deprecated: 'Use #FlutterDependenciesPackages visitFromLeaves instead'
		on: '16 February 2023'
		in:
		'Pharo-10.0.0+build.528.sha.296f1d3342e7e4ade13d9fc8179531388d9e62e3 (64 Bit)'.
	
	aDictionnary isEmpty ifTrue: [ ^ self ].

	leaves := aDictionnary.
	nextLeaves := Dictionary new.

	leaves do: [ :leafPkg | 
		
		"l is a FlutterPackage""traitement du package"
		aBlock value: leafPkg.


		leafPkg parentalDep do: [ :parent | 
			
			"modification de ces parents pour y changer ces references"
			aBlock value: leafPkg.

			nextLeaves at: parent name ifAbsentPut: [ parent ] ] ].


	self visitFromLeaves: nextLeaves withBlock: aBlock
]
