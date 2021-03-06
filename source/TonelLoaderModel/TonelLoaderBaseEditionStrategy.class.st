Class {
	#name : 'TonelLoaderBaseEditionStrategy',
	#superclass : 'TonelLoaderStrategy',
	#pools : [
		'TonelTextConstants'
	],
	#category : 'TonelLoaderModel'
}

{ #category : 'operations',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> confirmLoadPrerequisites: prereqNames of: applicationNames using: browser [

	^self loader confirm: ((NlsCatEMT residentMsg: 'MxEMT24') addLineDelimiters 
				bindWith: applicationNames
				with: prereqNames)
]

{ #category : 'lookup',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> findAllApplicationsToLoadWith: applications [

	"Private - Find all prerequisites of the applications which are not loaded and ask
	 the user if they should be loaded also. If not answer nil.
	 
	 NOTE: This is a modified version of EtBrowser's version, that delegates on receiver to use its own strategy.
	 "

	| browser required applicationNames stream prereqNames toLoad cursorPosition prereq others |
	browser := EtBrowser new.
	required := browser managerInterface 
				allUnloadedPrerequisitesFor: applications.
	required isEmpty ifTrue: [^applications].
	applications size = 1 
		ifTrue: [applicationNames := applications first name]
		ifFalse: 
			[stream := WriteStream on: (browser stringClass new: 100).
			(applications asSortedCollection: Class sortBlock) do: 
					[:app | 
					stream
						cr;
						nextPutAll: '      ' , app name].	"$NON-NLS$"
			applicationNames := stream contents].
	stream := WriteStream on: (browser stringClass new: 100).
	required keys asSortedCollection do: 
			[:appName | 
			stream
				cr;
				nextPutAll: '      ' , appName].	"$NON-NLS$"
	prereqNames := stream contents.
	(self 
		confirmLoadPrerequisites: prereqNames
		of: applicationNames
		using: browser) ifFalse: [^nil].	"$NLS$ To load %1 the following prerequisite(s) must also be loaded:\%2.\\Do you wish to load them also?"
	toLoad := applications asOrderedCollection.
	cursorPosition := System cursorPosition.
	required associationsDo: 
			[:assoc | 
			(toLoad detect: [:app | app symbol = assoc key] ifNone: []) isNil 
				ifTrue: 
					[assoc value isEmpty 
						ifTrue: 
							[| application |
							application := assoc key.
							^self signalMissingPrerequisiteOf: application].	"$NLS$ The prerequisite %1 does not exist in the library."
					assoc value size = 1 
						ifTrue: [prereq := assoc value first]
						ifFalse: 
							[| application prereqs |
							application := assoc key.
							prereqs := assoc value.
							prereq := self 
										selectPrerequisitesOf: application
										in: prereqs
										using: browser
										at: cursorPosition].
					prereq isNil ifTrue: [^nil].
					others := self findAllApplicationsToLoadWith: (Array with: prereq).
					others isNil ifTrue: [^nil].
					toLoad addAll: others]].
	^toLoad
]

{ #category : 'operations',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> loadBaseEditionAndPrerequisitesOf: baseEdition [

	^EmImageBuilder loadApplications: (self findAllApplicationsToLoadWith: (Array with: baseEdition))
]

{ #category : 'operations' }
TonelLoaderBaseEditionStrategy >> loadBaseEditionFor: aTonelSubApplication [

	"This method contains some voodoo."

	| baseEdition |
	baseEdition := self selectBaseEditionOf: aTonelSubApplication.	"$NLS$ Application %1 exists but is not loaded. Please choose a base version."	"$NLS$ %1 %2"
	baseEdition 
		ifNil: [self signalNoBaseEditionErrorFor: aTonelSubApplication].	"$NLS$ You need to choose a base edition from which to create %1"
	(self loadBaseEditionAndPrerequisitesOf: baseEdition) ifNil: 
			[self signalLoadErrorOf: aTonelSubApplication	"$NLS$ Could not load base edition of %1. Load aborted."]
]

{ #category : 'lookup',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> selectBaseEditionOf: aTonelSubApplication [

	self subclassResponsibility
]

{ #category : 'lookup',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> selectPrerequisitesOf: application in: prereqs using: browser at: cursorPosition [

	^self loader prerequisitesFor: application current: prereqs
]

{ #category : 'errors',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> signalLoadErrorOf: aTonelSubApplication [

	^TonelLoaderError signal: (TonelMsg18 bindWith: aTonelSubApplication)	"$NLS$ Could not load base edition of %1. Load aborted."
]

{ #category : 'errors',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> signalMissingPrerequisiteOf: application [

	TonelLoaderError signal: ((NlsCatEMT residentMsg: 'MxEMT25') bindWith: application).
	^nil
]

{ #category : 'errors',
  #vaVisibility : 'private' }
TonelLoaderBaseEditionStrategy >> signalNoBaseEditionErrorFor: aTonelSubApplication [

	^TonelLoaderError signal: (TonelMsg08 bindWith: aTonelSubApplication)
]
