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
DependenciesResolver class >> initWithPackagePath: packagePath andPubcachePath: pubspecPath [

	| dr |
	dr := DependenciesResolver new.
	dr pathPubCache: pubspecPath.
	dr originPkg: packagePath.
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
		| pkgPath exportPath|
		pkgPath := FileLocator C / pathPubCache / child exportPackageName.
			exportPath := (pkgExportedFolder / child exportPackageName).
		  exportPath exists ifFalse: [ 
			pkgPath copyAllTo: exportPath ].



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
	
		pkgPath := FileLocator C / pathPubCache / child exportPackageName.
	
		exportPath := (pkgExportedFolder / child exportPackageName).
		  exportPath exists ifFalse: [ 
			pkgPath copyAllTo: exportPath ].

		
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

	pkgExportedFolder := FileLocator home / 'PACKAGES/'.
	pkgExportedFolder ensureCreateDirectory.
	"	tempFolder := (FileLocator home / 'outputParserDart') asFileReference."
	pkgExportedFolder children do: [ :f | f deleteAll ].
	pathPubCache := ''
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
