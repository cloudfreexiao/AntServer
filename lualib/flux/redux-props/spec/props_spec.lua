local connect = require 'src.connect'
local Component = require 'src.component'
local Provider = require 'src.provider'
local reducers = require 'spec.reducers.index'
local createStore = require 'redux.createStore'
local Test1Actions = require 'spec.actions.test1'
local inspect = require 'redux.utils.inspect'
local assign = require 'redux.helpers.assign'

local store = createStore(reducers)

describe('ReduxProps', function ()
    describe('store', function ()
        it('bind store', function ()
            assert.has_error(function()
                Provider.setStore(function() end)
            end)
            assert.has_error(function()
                Provider.setStore({})
            end)
            assert.has_error(function()
                Provider.setStore(1)
            end)
            assert.has_no.errors(function()
                Provider.setStore(store)
            end)
            assert.has_no.errors(function()
                Provider.setStore(nil)
            end)
        end)

        it('component constructor', function ()
            local C1 = Component:extends()

            function C1:constructor(props)
                print('C1:constructor')
                Component.constructor(self, props)
                self.id = props.id
            end

            local c1 = C1:new({id = 2})
            assert.is_equal(c1.id, 2)
            assert.is_equal(c1.props.id, 2)

            local C2 = Component:extends()

            local c2 = C2:new({id = 3})
            assert.is_equal(c2.props.id, 3)

            local C3 = Component:extends()

            function C3:constructor(props)
                local _, _ = self, props
            end
            local c3 = C3:new({id = 4})
            assert.is_equal(c3.props, nil)

            local C4 = C1:extends()

            function C4:constructor(props)
                C1.constructor(self, props)
            end

            local c4 = C4:new({id = 5})
            assert.is_equal(c4.id, 5)
            assert.is_equal(C1.id, nil)
        end)

        it('connect with object', function ()
            Provider.setStore(store)

            local function mapStateToProps(state, ownProps)
                print('ownProps.........', inspect(ownProps))
                local test1 = state.test1 or {}
                return {
                    title = test1.title,
                    num = test1.num
                }
            end

            local index = 0
            local Handler = Component:extends()

            function Handler:propsWillChange(prev, next)
                print('Handler:reduxPropsWillChange', inspect(prev), inspect(next))
                print('self.props', inspect(self.props))
                index = index + 1
            end

            function Handler:propsDidChange()
                print('Handler:reduxPropsChanged', inspect(self.props))
            end

            local container = connect(mapStateToProps)(Handler)
            local instance = container()

            store.dispatch(Test1Actions.updateTitle('GitHub'))
            assert.is_equal(index, 2)

            store.dispatch(Test1Actions.updateUrl('https://github.com'))
            assert.is_equal(index, 2)

            store.dispatch(Test1Actions.updateFlag(true))
            assert.is_equal(index, 2)

            store.dispatch(Test1Actions.updateTitle('Redux'))
            assert.is_equal(index, 3)

            store.dispatch(Test1Actions.updateNum(index))
            assert.is_equal(index, 4)

            store.dispatch(Test1Actions.updateUrl('https://redux.js.org'))
            assert.is_equal(index, 4)

            instance:destroy()
            Provider.setStore(nil)
        end)
        it('callback', function ()
            print('=======================================')
            Provider.setStore(store)

            local function mapStateToProps(state, ownProps)
                print('ownProps.........', inspect(ownProps))
                return assign({}, state.test1)
            end

            local index = 0
            local Handler = Component:extends()

            function Handler:propsWillChange(prev, next)
                print('Handler:reduxPropsWillChange', inspect(prev), inspect(next))
                print('self.props', inspect(self.props))
                index = index + 1
            end

            function Handler:propsDidChange()
                print('Handler:reduxPropsChanged', inspect(self.props))
            end

            local container = connect(mapStateToProps)(Handler)
            local instance = container{
                id = 1
            }

            instance:updateProps{
                xxx = 2
            }

            store.dispatch(Test1Actions.updateUrl('https://google.com'))

            instance:updateProps{
                id = 2
            }

            print('destroy start')
            instance:destroy()
            print('destroy end')
            store.dispatch(Test1Actions.updateUrl('https://github.com'))
        end)
    end)
end)
