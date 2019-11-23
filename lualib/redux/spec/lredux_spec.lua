local ProfileActions = require 'examples.actions.profile'
local store = require 'examples.store'

describe('lredux', function ()
    describe('state', function ()
        it('init state', function ()
            assert.equals(next(store.getState()), nil)
        end)
        it('dispatch', function ()
            store.dispatch(ProfileActions.updateName('Jack'))
            assert.equals(store.getState().profile.name, 'Jack')

            store.dispatch(ProfileActions.updateAge(10))
            assert.equals(store.getState().profile.age, 10)

            store.dispatch(ProfileActions.done())
            assert.equals(next(store.getState()), nil)
        end)
    end)
end)
