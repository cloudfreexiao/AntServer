describe('min', function()
  it('produces an error if its parent errors', function()
    local observable = Rx.Observable.of(''):map(function(x) return x() end)
    expect(observable).to.produce.error()
    expect(observable:min()).to.produce.error()
  end)

  it('produces an error if one of the values produced is a string', function()
    local observable = Rx.Observable.of(1, 'string'):min()
    expect(observable).to.produce.error()
  end)

  it('produces the minimum of all values produced', function()
    local observable = Rx.Observable.fromRange(5):min()
    expect(observable).to.produce(1)
  end)
end)