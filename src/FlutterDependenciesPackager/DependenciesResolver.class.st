Class {
	#name : #DependenciesResolver,
	#superclass : #Object,
	#instVars : [
		'lock2json',
		'pkgExportedFolder',
		'pathPubCache',
		'originPkg'
	],
	#category : #FlutterDependenciesPackager
}

{ #category : #'as yet unclassified' }
DependenciesResolver class >> initWithPackagePath: packageFolder andPubcachePath: pubspecFolder [

	"
	Init the dependency resolver folder in which the package you inidicate will be packaged with it dependencies. 
	The pubspecFolder is necessary to get the dependencies packages download by flutter after a 'flutter pub get' command.
	
	packageAsFileReference: path to the package folder on which you want to do the packaging (as FileLocator/String/FileReference)
	pubspecPathAsString: path to the root of the .pub-cache in your machine User/u/.pubspec (as FileLocator/String/FileReference)
	
	example :
	dr := DependenciesResolver initWithPackagePath: 'C:\Users\myPackage' andPubcachePath: 'C:\Users\user\flutter\.pub-cache\'.  
		or 
	dr := DependenciesResolver initWithPackagePath: FileLocator home / 'myPackage' andPubcachePath: 'C:\Users\user\flutter\.pub-cache\'.
	"

	| dr exportTo pkgName pkgRef pubspecRef |
	pkgRef := packageFolder asFileReference.
	pubspecRef := pubspecFolder asFileReference.

	pkgName := pkgRef path at: pkgRef path size.

	dr := DependenciesResolver new.
	exportTo := FileLocator home / 'PACKAGES' / pkgName.
	exportTo ensureCreateDirectory.
	exportTo children do: [ :f | f deleteAll ].

	pkgRef copyAllTo: exportTo.
	"get the name of the projet from the last element of the path and ensure the creation of the packagedDependencies folder"
	(exportTo / pkgName / 'packagedDependencies/') ensureCreateDirectory.


	dr pkgExportedFolder:
		(exportTo / pkgName / 'packagedDependencies/') asFileReference.


	dr pathPubCache: pubspecRef.
	dr originPkg: pkgRef.
	^ dr
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> collectDependenciesOf: aFlutterPackage fromLockJson: aDictionnary [

	| packages |
	packages := aDictionnary at: 'packages'.

	"Filter the dependencies to only keep packages that are not from the SDK"
	aFlutterPackage childrenDep:
		(aFlutterPackage childrenDep select: [ :aPkg | 
			 (((packages at: aPkg name) at: 'source') = 'sdk') not ]).

	aFlutterPackage childrenDep do: [ :aPkg | 
		aPkg version: ((packages at: aPkg name) at: 'version').
		aPkg source: ((packages at: aPkg name) at: 'source') ].

]

{ #category : #'as yet unclassified' }
DependenciesResolver >> exploreDirectDependencies: aFlutterPackage [

	"create a new package instance"

	self collectDependenciesOf: aFlutterPackage fromLockJson: lock2json.

	aFlutterPackage childrenDep do: [ :child | 
		| pkgPath exportPath |
		
			pkgPath := ''.
		child source = 'hosted' ifTrue:[
			pkgPath := FileLocator C / pathPubCache / 'hosted' / 'pub.dartlang.org' /child exportPackageName.
			].
		child source = 'git' ifTrue:[
			1 halt.
			"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
			"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName."
			].
		
		
		exportPath := pkgExportedFolder / child exportPackageName.
		exportPath exists ifFalse: [ pkgPath copyAllTo: exportPath ].



		child initFromPath: pkgPath.
		self exploreDirectDependencies: child ]
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> exploreFromAPackage: packageAsFileLocator [

	| pkg |
	"create a new package instance"
	pkg := FlutterPackage new.
	pkg initMainPackageFromPath: packageAsFileLocator.

	"because this package is the entry point, get its pubspec.lock as Json"
	lock2json := pkg getJsonFromPubspecLock: pkg pubpspecLockFileLocator.
	self collectDependenciesOf: pkg fromLockJson: lock2json.

	pkg childrenDep do: [ :child | 
		| pkgPath exportPath |
		
		
		pkgPath := ''.
		child source = 'hosted' ifTrue:[
			pkgPath := FileLocator C / pathPubCache / 'hosted' / 'pub.dartlang.org' /child exportPackageName.
			].
		child source = 'git' ifTrue:[
			1 halt.
			"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
			"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName."
			].
		

		exportPath := pkgExportedFolder / child exportPackageName.
		exportPath exists ifFalse: [ pkgPath copyAllTo: exportPath ].


		child initFromPath: pkgPath.
		self exploreDirectDependencies: child ].

	^ pkg
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> explorePackage: aPathasString [

	| pkg |
	"create a new package instance"
	pkg := FlutterPackage new.
	pkg initFromPath: aPathasString.
	lock2json := pkg getJsonFromPubspecLock: pkg pubpspecLockFileLocator.
	self collectDependenciesOf: pkg fromLockJson: lock2json.

	pkg childrenDep do: [ :child | 
		| path |
		path := FileLocator home
		        /
		        ('.pub-cache/hosted/pub.dartlang.org/'
		         , child exportPackageName).
		].
	1 halt.
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> initialize [
]

{ #category : #getter }
DependenciesResolver >> originPkg [
	^ originPkg
]

{ #category : #setter }
DependenciesResolver >> originPkg: aFileLocator [ 
	originPkg := aFileLocator
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> pathPubCache: aPath [

	pathPubCache := aPath
]

{ #category : #setter }
DependenciesResolver >> pkgExportedFolder: aFileReference [ 
	pkgExportedFolder := aFileReference
]
