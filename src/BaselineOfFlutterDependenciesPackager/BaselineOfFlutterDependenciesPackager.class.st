Class {
	#name : #BaselineOfFlutterDependenciesPackager,
	#superclass : #BaselineOf,
	#category : #BaselineOfFlutterDependenciesPackager
}

{ #category : #baselines }
BaselineOfFlutterDependenciesPackager >> baseline: spec [
 "donne l'ensmebe des package requis pour la baseline (à inclure dans l'archive définis par Iceberg)"
	<baseline>
	spec for: #common do: [ 
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec ]
]

{ #category : #baselines }
BaselineOfFlutterDependenciesPackager >> defineDependencies: spec [

	"donne les ref vers le projet qui se trouve sur un depot distance (je crois)"

	spec
		baseline: 'MermaidPharo'
		with: [ spec repository: 'github://badetitou/MermaidPharo' ];
		baseline: 'yaml2json'
		with: [ spec repository: 'github:///Evref-BL/yaml2json' ]
]

{ #category : #baselines }
BaselineOfFlutterDependenciesPackager >> defineGroups: spec [
"aucune idée"
]

{ #category : #baselines }
BaselineOfFlutterDependenciesPackager >> definePackages: spec [

	"mentionne l'ensemble des packages requis"

	spec package: 'FlutterDependenciesPackager' with: [ 
		spec
			requires: #( 'MermaidPharo' 'yaml2json' )]
]
