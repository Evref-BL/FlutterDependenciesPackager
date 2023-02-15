Class {
	#name : #DependenciesResolver,
	#superclass : #Object,
	#instVars : [
		'lock2json',
		'pkgExportedFolder',
		'pathPubCache',
		'exportPkg',
		'dicoPackages'
	],
	#category : #FlutterDependenciesPackager
}

{ #category : #initialize }
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
	dr := DependenciesResolver new.
	dr dicoPackages: Dictionary new.

	pkgRef := packageFolder asFileReference.
	pubspecRef := pubspecFolder asFileReference.

	pkgName := pkgRef path at: pkgRef path size.



	exportTo := FileLocator home / 'PACKAGES' / pkgName.
	exportTo ensureCreateDirectory.
	dr exportPkg: exportTo.
	exportTo children do: [ :f | f deleteAll ].

	pkgRef copyAllTo: exportTo.
	"get the name of the projet from the last element of the path and ensure the creation of the packagedDependencies folder"
	(exportTo / 'packagedDependencies/') ensureCreateDirectory.


	dr pkgExportedFolder:
		(exportTo / 'packagedDependencies/') asFileReference.


	dr pathPubCache: pubspecRef.

	^ dr
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> analysePubspecYaml: aFileReference withDevDependencies: aBoolean [

	"extract dependencency and info from a pubspec.yaml concerning a specific package"

	| y2j json dependencies |
	dependencies := OrderedCollection new.

	"convert pubspec.yaml to json (Dictionnary)"
	y2j := Yaml2Json new.
	json := STONJSON fromString:
		        (y2j convertPubSpecYamlToJson: aFileReference contents).

	"get official name of the package"
	(self dicoPackages at: (json at: #name)) name: (json at: #name).

	"get the direct dependencies (direct main) "
	dependencies := (json at: #dependencies ifAbsent: Dictionary new)
		                keys collect: [ :keyName | 
							dicoPackages at: keyName ifAbsentPut: [ FlutterPackage withName: keyName ].
		                "FlutterPackage withName: k withParent: self" ].

	"if necessary, get the dev dependencies"
	aBoolean ifTrue: [ 
		dependencies := dependencies
		                ,
			                ((json
				                  at: #dev_dependencies
				                  ifAbsent: Dictionary new) keys collect: [ :k | 
				                 dicoPackages at: k ifAbsentPut: [ FlutterPackage withName: k ].
		                "FlutterPackage withName: k withParent: self" ])
				                asOrderedCollection ].

	"store all dependencies"
	(self dicoPackages at: (json at: #name)) childrenDep:
		dependencies asOrderedCollection.

	^ self dicoPackages at: (json at: #name)
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> collectDependenciesOf: aFlutterPackage fromLockJson: aDictionnary [

	| packages |
	packages := aDictionnary at: #packages.



	"get info on direct dependencies "
	aFlutterPackage childrenDep do: [ :aPkg | 
		aPkg version: (packages at: aPkg name at: #version).
		aPkg source: (packages at: aPkg name at: #source) ].

	aFlutterPackage childrenDep do: [ :aPkg | 
		aPkg source = #sdk ifTrue: [ self dicoPackages removeKey: aPkg name ] ].

	"Filter the dependencies to only keep packages that are not from the SDK"
	aFlutterPackage childrenDep:
		(aFlutterPackage childrenDep select: [ :aPkg | 
			 ((packages at: aPkg name at: #source) = #sdk) not ])
]

{ #category : #getter }
DependenciesResolver >> dicoPackages [
	^ dicoPackages
]

{ #category : #setter }
DependenciesResolver >> dicoPackages: aCollection [

	dicoPackages := aCollection asDictionary
]

{ #category : #exploration }
DependenciesResolver >> exploreDirectDependencies: aFlutterPackage [

	"create a new package instance"

	| currentPkgPath currentExportPath |

	currentPkgPath := self pathFromPackageSource: aFlutterPackage.

	currentExportPath := pkgExportedFolder
	                     / aFlutterPackage exportPackageName.

	currentExportPath exists ifFalse: [ 
		currentPkgPath copyAllTo: currentExportPath ].

	aFlutterPackage path: currentExportPath.

	self
		analysePubspecYaml: aFlutterPackage pubspecyaml
		withDevDependencies: false.

	self collectDependenciesOf: aFlutterPackage fromLockJson: lock2json.

	aFlutterPackage childrenDep do: [ :child | 
		child addParentalDep: aFlutterPackage.
		self exploreDirectDependencies:
			(dicoPackages at: child name ifAbsentPut: [ child ]) ]
]

{ #category : #exploration }
DependenciesResolver >> exploreFromAPackage: packageAsFileLocator [

	| pkg mainPkgPath |
	"create a new package instance"
	mainPkgPath := packageAsFileLocator asFileReference.

	pkg := FlutterPackage initWithPath: mainPkgPath.
	dicoPackages at: pkg name ifAbsentPut: [ pkg ].
	pkg := self
		       analysePubspecYaml: pkg pubspecyaml
		       withDevDependencies: true.

	"because this package is the entry point, get its pubspec.lock as Json"
	lock2json := pkg getJsonFromPubspecLock: pkg pubpspecLockFileLocator.
	self collectDependenciesOf: pkg fromLockJson: lock2json.

	"explore children dependencies"
	pkg childrenDep do: [ :child | 
		child addParentalDep: pkg.

		self exploreDirectDependencies:
			(dicoPackages at: child name ifAbsentPut: [ child ]) ].

	^ pkg
]

{ #category : #getter }
DependenciesResolver >> exportPkg [
	^ exportPkg
]

{ #category : #setter }
DependenciesResolver >> exportPkg: aFileLocator [

	exportPkg := aFileLocator asFileReference.
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> initialize [
]

{ #category : #exploration }
DependenciesResolver >> pathFromPackageSource: aFlutterPackage [

	"Construct the proper path of the original package depending on the type of dependencies (from git or hosted on pub dev)"
	| currentPkgPath |
	aFlutterPackage source = #hosted ifTrue: [ 
		currentPkgPath := pathPubCache / 'hosted' / 'pub.dartlang.org'
		                  / aFlutterPackage exportPackageName ].
	aFlutterPackage source = #git ifTrue: [ 
		self shouldBeImplemented
		"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
		"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName." ].
	^ currentPkgPath
]

{ #category : #'as yet unclassified' }
DependenciesResolver >> pathPubCache: aPath [

	pathPubCache := aPath asFileReference
]

{ #category : #setter }
DependenciesResolver >> pkgExportedFolder: aFileReference [

	pkgExportedFolder := aFileReference asFileReference
]
