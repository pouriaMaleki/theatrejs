_Emitter = require './_Emitter'
Prop = require './dynamic/Prop'
IncrementalIsolate = require './dynamic/IncrementalIsolate'

module.exports = class DynamicTimeFlow extends _Emitter

	constructor: (fps = 60) ->

		super

		@t = 0

		unless Number.isFinite(fps)

			throw Error "Fps must be a finite integer"

		@fps = parseInt fps

		@_frameLength = 1000 / @fps

		@_fpsT = @_calcuateFpsT @t

		@_arrays = {}

		@_incrementalIsolates = {}

		@_allProps = {}

		@_regularProps = {}

		@timelineLength = 0

	_calcuateFpsT: (t) ->

		parseInt Math.floor(t / @_frameLength) * @_frameLength

	_maximizeTimelineLength: (dur) ->

		@timelineLength = Math.max(dur, @timelineLength)

		@_emit 'length-change'

		return

	addArray: (name, array) ->

		if @_arrays[name]?

			throw Error "An array named '#{name}' already exists"

		@_arrays[name] = array

		@

	_verifyPropAdd: (id, arrayName, indexInArray) ->

		if @_allProps[id]?

			throw Error "A prop named '#{id}' already exists"

		unless @_arrays[arrayName]?

			throw Error "Couldn't find array named '#{arrayName}'"

		unless @_arrays[arrayName][indexInArray]?

			throw Error "Array '#{arrayName}' doesn't have an index of '#{indexInArray}'"

		return

	addProp: (id, arrayName, indexInArray) ->

		@_verifyPropAdd id, arrayName, indexInArray

		@_regularProps[id] = @_allProps[id] = new Prop @, id, arrayName, indexInArray

	defineIncrementalIsolate: (id, isolate) ->

		if @_incrementalIsolates[id]?

			throw Error "Another incremental isolate already exists with id '#{id}'"

		@_incrementalIsolates[id] = new IncrementalIsolate @, id, isolate

	getProp: (id) ->

		@_regularProps[id]

	tick: (t) ->

		fpsT = @_calcuateFpsT t

		if t < @t

			@_tickBackward fpsT

		else

			@_tickForward fpsT

		for name, ic of @_incrementalIsolates

			ic._tickForTimeFlow fpsT

		@_fpsT = fpsT
		@t = t

		@_emit 'tick'

		return

	_pluckFromRegularProps: (prop) ->

		delete @_regularProps[prop.id]

		return

	_tickForward: (t) ->

		for name, prop of @_regularProps

			prop._tickForward t

		return

	_tickBackward: (t) ->

		for name, prop of @_regularProps

			prop._tickBackward t

		return