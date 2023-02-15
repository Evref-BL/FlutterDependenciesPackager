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
