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

	| dp dr root dico leaves |
	dr := DependenciesResolver
		      initWithPackagePath: originPathOfPackage
		      andPubcachePath: pathOfPubCacheRoot.
	root := dr exploreFromAPackage: dr exportPkg.
	dico := dr dicoPackages.

	dr exportMermaidFile.

	"recupere les packages qui n'ont pas de dependance sortant (Children dep)"
	leaves := dico select: [ :pkg | pkg childrenDep isEmpty ].

	dp := FlutterDependenciesPackager new.
	dp modifyAllYaml: dico.
	dp visitFromLeaves: leaves.
	
	^ dr exportPkg
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> changeExportDQDecl: aString From: initialPkgName to: newPkgName [

	| newRegex res substitute |
	newRegex := ('export \"package\:' , initialPkgName , '\/') asRegex.
	substitute := String streamContents: [ :str | 
		              str << 'export \"package:' << newPkgName << '/' ].
	res := String streamContents: [ :out | 
		       aString readStreamDo: [ :stream | 
			       newRegex
				       copyStream: stream
				       to: out
				       replacingMatchesWith: substitute ] ].


	"	newRegex := ('import ''package\:',initialPkgName,'/').
	aString lines do: [ :line
		
		 ]"

	^ res
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> changeExportSQDecl: aString From: initialPkgName to: newPkgName [

	| newRegex res substitute |
	newRegex := ('export ''package\:' , initialPkgName , '\/') asRegex.
	substitute := String streamContents: [ :str | 
		              str << 'export ''package:' << newPkgName << '/' ].
	res := String streamContents: [ :out | 
		       aString readStreamDo: [ :stream | 
			       newRegex
				       copyStream: stream
				       to: out
				       replacingMatchesWith: substitute ] ].


	"	newRegex := ('import ''package\:',initialPkgName,'/').
	aString lines do: [ :line
		
		 ]"

	^ res
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> changeImportDQDecl: aString From: initialPkgName to: newPkgName [

	| newRegex res substitute |
	newRegex := ('import \"package\:' , initialPkgName , '\/') asRegex.
	substitute := String streamContents: [ :str | 
		              str << 'import \"package:' << newPkgName << '/' ].
	res := String streamContents: [ :out | 
		       aString readStreamDo: [ :stream | 
			       newRegex
				       copyStream: stream
				       to: out
				       replacingMatchesWith: substitute ] ].


	"	newRegex := ('import ''package\:',initialPkgName,'/').
	aString lines do: [ :line
		
		 ]"

	^ res
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> changeImportSQDecl: aString From: initialPkgName to: newPkgName [
	
			| newRegex res substitute |
	newRegex := ('import ''package\:',initialPkgName,'\/') asRegex.
		substitute := String streamContents: [ :str | 
		              str << 'import ''package:' << newPkgName << '/'].
	res := String streamContents: [ :out | 
			       aString readStreamDo: [ :stream | 
				       newRegex
					       copyStream: stream
					       to: out
					       replacingMatchesWith: substitute  ] ].
			
			
"	newRegex := ('import ''package\:',initialPkgName,'/').
	aString lines do: [ :line
		
		 ]"
	
	^ res
	
	
]

{ #category : #refactoring }
FlutterDependenciesPackager >> modifyAllYaml: aDictionary [ 
	
	
	
	aDictionary do:[ :pkg |
	pkg parentalDep isEmpty ifTrue: [ 
		self modifyTheRootYamlOf: pkg.
		 ] ifFalse: [ self modifyYamlOf: pkg.  ]
	
	]
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> modifyDartFilesOf: aFlutterPackage byReplacing: initialPkgName to: newPkgName [

	(aFlutterPackage path allChildrenMatching: '*.dart') do: [ :file | 
		| fileStream content |
		"Read the entire stream into a string"
		fileStream := file readStream.
		content := fileStream upToEnd.

		"Close the stream"
		fileStream close.

		content := self
			           changeImportSQDecl: content
			           From: initialPkgName
			           to: newPkgName.
		content := self
			           changeImportDQDecl: content
			           From: initialPkgName
			           to: newPkgName.

		content := self
			           changeExportSQDecl: content
			           From: initialPkgName
			           to: newPkgName.
		content := self
			           changeExportDQDecl: content
			           From: initialPkgName
			           to: newPkgName.

		file
			delete;
			writeStreamDo: [ :stream | stream << content ] ]
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> modifyTheRootYamlOf: aFlutterPackage [

	"rewrite the pubspec.yaml file by changing the name of aFlutterPackage declare in this file. Replace it by the valide package name"

	| yamlApi yaml builtins in out python_dict path dependencies  |
	yamlApi := PyBridge load: #'ruamel.yaml::YAML'.
	yaml := yamlApi new.

	builtins := PyBridge loadClass: #builtins.

	"store the path of the yaml file as a String"
	path := aFlutterPackage pubspecyaml asFileReference pathString.
	in := builtins open: path mode: #r.
	python_dict := yaml load: in.
	in close.
	python_dict
		at: #name
		put:
		(PyBridgeObjectLiteral with:
			 aFlutterPackage aValidFlutterPackageName).



	aFlutterPackage childrenDep isNotEmpty ifTrue: [ 
		dependencies := python_dict at: #dependencies.

		aFlutterPackage childrenDep do: [ :dep | 
			| newValue newPath |
			newValue := Dictionary new.
			newPath := './packagedDependencies/' , dep exportPackageName , '/'.
			newValue at: #path ifAbsentPut: newPath.
			dependencies at: dep aValidFlutterPackageName put: newValue.
			dependencies at: dep name put: ''.
			dependencies pop: dep name ] ].


	"rewrite the file"
	out := builtins open: path mode: #w.
	yaml dump: python_dict out: out.
	out close
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> modifyYamlOf: aFlutterPackage [

	"rewrite the pubspec.yaml file by changing the name of aFlutterPackage declare in this file. Replace it by the valide package name"

	| yamlApi yaml builtins in out python_dict path dependencies hasDependencies |
	yamlApi := PyBridge load: #'ruamel.yaml::YAML'.
	yaml := yamlApi new.

	builtins := PyBridge loadClass: #builtins.

	"store the path of the yaml file as a String"
	path := aFlutterPackage pubspecyaml asFileReference pathString.


	in := builtins open: path mode: #r.
	python_dict := yaml load: in.
	in close.

	python_dict
		at: #name
		put:
		(PyBridgeObjectLiteral with:
			 aFlutterPackage aValidFlutterPackageName).



	aFlutterPackage childrenDep isNotEmpty ifTrue: [ 
		dependencies := python_dict at: #dependencies.

		aFlutterPackage childrenDep do: [ :dep | 
			| newValue newPath |
			newValue := Dictionary new.
			newPath := '../' , dep exportPackageName , '/'.
			newValue at: #path ifAbsentPut: newPath.
			dependencies at: dep aValidFlutterPackageName put: newValue.
			dependencies pop: dep name ] ].


	"rewrite the file"
	out := builtins open: path mode: #w.
	yaml dump: python_dict out: out.
	out close
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> refactorPackage: aFlutterPackage [


	"self modifyYamlOf: aFlutterPackage."

	"change self reference in port"

	"p.ex. ::  import 'package:PACKAGE_NAME/*.dart';"

	self
		modifyDartFilesOf: aFlutterPackage
		byReplacing: aFlutterPackage name
		to: aFlutterPackage aValidFlutterPackageName.


	^ aFlutterPackage
]

{ #category : #'as yet unclassified' }
FlutterDependenciesPackager >> refactorParentDependenciesOf: aFlutterPackage [

	aFlutterPackage parentalDep do: [ :pkg | 

		self
			modifyDartFilesOf: pkg
			byReplacing: aFlutterPackage name
			to: aFlutterPackage aValidFlutterPackageName ].

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
