"
This class is responsible for refactoring the dependencies and thus to package the flutter app. 




For the Class part:  State a one line summary. For example, ""I represent a paragraph of text"".

For the Responsibility part: Three sentences about my main responsibilities - what I do, what I know.

For the Collaborators Part: State my main collaborators and one line about how I interact with them. 

Public API and Key Messages

- message one   
- message two 
- (for bonus points) how to create instances.

   One simple example is simply gorgeous.
 
Internal Representation and Key Implementation Points.


    Implementation Points
"
Class {
	#name : #FlutterDependenciesPackager,
	#superclass : #Object,
	#instVars : [
		'mainPackage',
		'dicoPackages',
		'depResolver'
	],
	#category : #FlutterDependenciesPackager
}

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager class >> applyOn: originPathOfPackage withPubCacheIn: pathOfPubCacheRoot [

	| dp dr root dico leaves "dg file" |
	dr := DependenciesResolver initWithPackagePath: originPathOfPackage andPubcachePath: pathOfPubCacheRoot. 
	root := (dr exploreFromAPackage: dr exportPkg).
	dico := dr dicoPackages.
	
	dr exportMermaidFile. 
	
"	dg := DependencyGraph new.
	dg buildGraphFrom: root withData: dr dicoPackages.
	
	file := dr exportPkg / (root name, '_graph.mermaid').
	file ensureCreateFile. 
	(file writeStream) nextPutAll: (dg flowGraph exportWith: dg flowGraph class defaultWritter new); close."
	
	
	"recupere les packages qui n'ont pas de dependance sortant (Children dep)"
	leaves := dico select: [ :pkg |
	pkg childrenDep isEmpty.
	 ].

	dp := FlutterDependenciesPackager new.
	dp visitFromLeaves: leaves. 
	^ dr exportPkg. 
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> refactorPackage: aFlutterPackage [
	
	self flag: 'TODO'.
	
	^ aFlutterPackage
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> refactorParentDependenciesOf: aFlutterPackage [
	
	aFlutterPackage parentalDep do: [ :pkg |
			self flag: 'TODO'.
		 ].
	
	^ aFlutterPackage
]

{ #category : #visiting }
FlutterDependenciesPackager >> visitFromLeaves: aDictionnary [

	"recursion start here"

	| nextLeaves leaves |
	Transcript show: aDictionnary keys size; cr.
	
	aDictionnary isEmpty ifTrue: [ ^ self ].

	leaves := aDictionnary.
	nextLeaves := Dictionary new.

	"parcours des packages flutter qui n'ont pas de dependence enfant"
	leaves do: [ :leafPkg | 
		
		self refactorPackage: leafPkg.
		self refactorParentDependenciesOf: leafPkg.
		
		"on ajoute dans le nouveau dico les prochains pkg a traiter"
		leafPkg parentalDep do: [ :parent | 
			nextLeaves at: parent name ifAbsentPut: [ parent ] ] ].

	
	self visitFromLeaves: nextLeaves 
]
