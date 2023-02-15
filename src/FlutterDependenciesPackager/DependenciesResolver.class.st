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

	self
		deprecated: 'Use #exploreDirectDependenciesV4: instead'
		on: '15 February 2023'
		in:
		'Pharo-10.0.0+build.528.sha.296f1d3342e7e4ade13d9fc8179531388d9e62e3 (64 Bit)'.

	self collectDependenciesOf: aFlutterPackage fromLockJson: lock2json.

	aFlutterPackage childrenDep do: [ :child | 
		| pkgPath exportPath |
		pkgPath := ''.

		child source = 'hosted' ifTrue: [ 
			pkgPath := pathPubCache / 'hosted' / 'pub.dartlang.org'
			           / child exportPackageName ].
		child source = 'git' ifTrue: [ 
			1 halt
			"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
			"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName." ].


		"Copy this dependency package to the export path and call initFromPath from the new location"
		exportPath := pkgExportedFolder / child exportPackageName.
		exportPath exists ifFalse: [ pkgPath copyAllTo: exportPath ].
		child initFromPath: exportPath.

		self exploreDirectDependencies: child ]
]

{ #category : #exploration }
DependenciesResolver >> exploreDirectDependenciesV3: aFlutterPackage [

	"create a new package instance"

	self
		deprecated: 'Use #exploreDirectDependenciesV4: instead'
		on: '15 February 2023'
		in:
		'Pharo-10.0.0+build.528.sha.296f1d3342e7e4ade13d9fc8179531388d9e62e3 (64 Bit)'.
	self
		analysePubspecYaml: aFlutterPackage pubspecyaml
		withDevDependencies: false.
	self collectDependenciesOf: aFlutterPackage fromLockJson: lock2json.

	aFlutterPackage childrenDep do: [ :child | 
		| pkgPath exportPath |
		pkgPath := ''.

		child source = #hosted ifTrue: [ 
			pkgPath := pathPubCache / 'hosted' / 'pub.dartlang.org'
			           / child exportPackageName ].
		child source = #git ifTrue: [ 
			self shouldBeImplemented
			"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
			"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName." ].

		"Copy this dependency package to the export path and call initFromPath from the new location"
		exportPath := pkgExportedFolder / child exportPackageName.
		exportPath exists ifFalse: [ pkgPath copyAllTo: exportPath ].
		child path: exportPath.
		self
			analysePubspecYaml: child pubspecyaml
			withDevDependencies: false.
		child addParentalDep: aFlutterPackage.

		self exploreDirectDependenciesV3:
			(dicoPackages at: child name ifAbsentPut: [ child ]) ]
]

{ #category : #exploration }
DependenciesResolver >> exploreDirectDependenciesV4: aFlutterPackage [

	"create a new package instance"

	| currentPkgPath currentExportPath |
	
	aFlutterPackage exportPackageName = 'google_sign_in_web-0.10.0+5' ifTrue: [ 1 halt. ].
	
	
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
		self exploreDirectDependenciesV4:
			(dicoPackages at: child name ifAbsentPut: [ child ]) ]
]

{ #category : #exploration }
DependenciesResolver >> exploreFromAPackage: packageAsFileLocator [

	| pkg mainPkgPath |
	"create a new package instance"
	self
		deprecated: 'Use #exploreFromAPackageV4: instead'
		on: '15 February 2023'
		in:
		'Pharo-10.0.0+build.528.sha.296f1d3342e7e4ade13d9fc8179531388d9e62e3 (64 Bit)'.
	mainPkgPath := packageAsFileLocator asFileReference.

	pkg := FlutterPackage new.
	pkg initMainPackageFromPath: mainPkgPath.

	"because this package is the entry point, get its pubspec.lock as Json"
	lock2json := pkg getJsonFromPubspecLock: pkg pubpspecLockFileLocator.
	self collectDependenciesOf: pkg fromLockJson: lock2json.



	pkg childrenDep do: [ :child | 
		| pkgPath exportPath |
		pkgPath := ''.

		"Construct the proper path of the original package depending on the type of dependencies (from git or hosted on pub dev)"
		child source = #hosted ifTrue: [ 
			pkgPath := pathPubCache / 'hosted' / 'pub.dartlang.org'
			           / child exportPackageName ].
		child source = #git ifTrue: [ 
			self shouldBeImplemented
			"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
			"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName." ].

		"Copy this dependency package to the export path and call initFromPath from the new location"
		exportPath := pkgExportedFolder / child exportPackageName.
		exportPath exists ifFalse: [ pkgPath copyAllTo: exportPath ].
		child initFromPath: exportPath.

		self exploreDirectDependencies: child ].

	^ pkg
]

{ #category : #exploration }
DependenciesResolver >> exploreFromAPackageV3: packageAsFileLocator [

	| pkg mainPkgPath |
	"create a new package instance"
	self
		deprecated: 'Use #exploreFromAPackageV4: instead'
		on: '15 February 2023'
		in:
		'Pharo-10.0.0+build.528.sha.296f1d3342e7e4ade13d9fc8179531388d9e62e3 (64 Bit)'.
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
		| pkgPath exportPath |
		pkgPath := ''.

		"Construct the proper path of the original package depending on the type of dependencies (from git or hosted on pub dev)"
		child source = #hosted ifTrue: [ 
			pkgPath := pathPubCache / 'hosted' / 'pub.dartlang.org'
			           / child exportPackageName ].
		child source = #git ifTrue: [ 
			self shouldBeImplemented
			"TODO !!!  recuperer package <name + resolved-ref> à la place de version pour exportPackageName !"
			"pkgPath := FileLocator C / pathPubCache / 'git' / 'pub.dartlang.org' /child exportPackageName." ].

		"Copy this dependency package to the export path and call initFromPath from the new location"
		exportPath := pkgExportedFolder / child exportPackageName.
		exportPath exists ifFalse: [ pkgPath copyAllTo: exportPath ].
		child path: exportPath.
		child addParentalDep: pkg.


		self exploreDirectDependenciesV3:
			(dicoPackages at: child name ifAbsentPut: [ child ]) ].

	^ pkg
]

{ #category : #exploration }
DependenciesResolver >> exploreFromAPackageV4: packageAsFileLocator [

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

		self exploreDirectDependenciesV4:
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
