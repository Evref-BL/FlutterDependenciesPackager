Class {
	#name : #DependencyGraph,
	#superclass : #Object,
	#instVars : [
		'root',
		'packages',
		'flowGraph'
	],
	#classVars : [
		'packagesV2'
	],
	#category : #FlutterDependenciesPackager
}

{ #category : #initialization }
DependencyGraph >> buildGraph: aFlutterPackage [

	| currentNode |
	self flowGraph definitions isEmpty ifTrue: [ root := aFlutterPackage ].

	currentNode := MeFCNode named: aFlutterPackage exportPackageName.


	(packages includes: aFlutterPackage) ifFalse: [ 
		packages add: aFlutterPackage.
		flowGraph addDefinition: currentNode ].

	aFlutterPackage childrenDep do: [ :dep | 
		| link childNode |
		childNode := MeFCNode named: dep exportPackageName.

		(packages includes: dep) ifFalse: [ 
			flowGraph addDefinition: childNode.
			packages add: dep ].

		link := MeFCLink newFromNode: currentNode toNode: childNode.
		link toArrowType: MeFCArrowHeadType new.
		flowGraph addDefinition: link.
		self buildGraph: dep ].

	^ self.
]

{ #category : #initialization }
DependencyGraph >> buildGraphFrom: aFlutterPackage withData: aDictionnary [

	| currentNode nodesDico linksDico |
	"flowGraph := MeFlowchartDiagram new"
	self flowGraph definitions isEmpty ifTrue: [ root := aFlutterPackage ].
	nodesDico := Dictionary new.
	linksDico := Dictionary new.

	aDictionnary do: [ :each | 
		currentNode := MeFCNode named: each exportPackageName.
		nodesDico at: currentNode name ifAbsentPut: [ currentNode ] ].



	aDictionnary do: [ :each | 
		currentNode := nodesDico at: each exportPackageName.


		each childrenDep do: [ :dep | 
			| link toNode |
			toNode := nodesDico at: dep exportPackageName.

			link := MeFCLink newFromNode: currentNode toNode: toNode.
			link toArrowType: MeFCArrowHeadType new.
			linksDico at: currentNode name , toNode name ifAbsentPut: [ link ] ] ].

	nodesDico do: [ :n | flowGraph addDefinition: n ].
	linksDico do: [ :n | flowGraph addDefinition: n ].

	^ self
]

{ #category : #initialization }
DependencyGraph >> buildGraphFromV2: aFlutterPackage withData: aDictionnary [

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
DependencyGraph >> buildGraphV2: aFlutterPackage [

	| currentNode |
	self flowGraph definitions isEmpty ifTrue: [ root := aFlutterPackage ].

	currentNode := MeFCNode named: aFlutterPackage exportPackageName.

	(packages includes: aFlutterPackage) ifFalse: [ 
		packages add: aFlutterPackage.
		flowGraph addDefinition: currentNode ].

	aFlutterPackage childrenDep do: [ :dep | 
		| link childNode |
		childNode := MeFCNode named: dep exportPackageName.

		(packages includes: dep) ifFalse: [ 
			flowGraph addDefinition: childNode.
			packages add: dep ].

		link := MeFCLink newFromNode: currentNode toNode: childNode.
		link toArrowType: MeFCArrowHeadType new.
		flowGraph addDefinition: link.
		self buildGraph: dep ].

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
	packages := OrderedCollection new.
	flowGraph := MeFlowchartDiagram new
]
