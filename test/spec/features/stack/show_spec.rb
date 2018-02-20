describe 'stack show' do
  after(:each) do
    run 'kontena stack rm --force simple'
  end

  it "shows a stack details" do
    with_fixture_dir("stack/simple") do
      run! 'kontena stack install --no-deploy'
    end
    k = run! "kontena stack show simple"
    expect(k.out.match(/^simple:/)).to be_truthy
    expect(k.out.match(/^\s+stack: test\/simple/)).to be_truthy
    expect(k.out.match(/^\s+revision: 1\s*$/)).to be_truthy
    expect(k.out.match(/^\s+revision:\s*$/)).to be_truthy
  end

  it 'returns error if stack does not exist' do
    k = run "kontena stack show simple"
    expect(k.code).not_to eq(0)
    expect(k.out.match(/not found/i)).to be_truthy
  end

  it 'includes stack metadata' do
    with_fixture_dir("stack/metadata") do
      run! 'kontena stack install -n simple --no-deploy'
    end

    k = run! "kontena stack show simple"
    expect(k.out.match(/^simple:/)).to be_truthy
    expect(k.out.match(/^\s+metadata:/)).to be_truthy
    expect(k.out.match(/^\s+tags:/)).to be_truthy
    expect(k.out.match(/^\s+- tag1/)).to be_truthy
  end
end
