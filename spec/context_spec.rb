require 'spec_helper'

describe 'context', type: :render do
  FooContext = Rux.create_context("foo")
  FooContextWithBlock = Rux.create_context { "foo from block" }

  class FooComponent < ViewComponent::Base
    def call
      context = Rux.use_context(FooContext)
      Rux::SafeString.new("<p>#{context}</p>")
    end
  end

  class FooComponentWithBlock < ViewComponent::Base
    def call
      context = Rux.use_context(FooContextWithBlock)
      Rux::SafeString.new("<p>#{context}</p>")
    end
  end

  describe '#context_key' do
    it 'uses the class name in the key' do
      expect(FooContext.context_key).to eq("FooContext_context")
      expect(FooContextWithBlock.context_key).to eq("FooContextWithBlock_context")
    end

    it "uses a random ID if the class doesn't have a name" do
      no_name = Rux.create_context
      expect(no_name.context_key).to match(/[a-f0-9-]{32}_context/)
    end

    it 'returns the same value when called multiple times' do
      no_name = Rux.create_context
      key = no_name.context_key
      expect(no_name.context_key).to eq(key)
    end
  end

  describe 'rendering' do
    it 'uses the given context value' do
      result = render(<<~RUX)
        <FooContext value="bar">
          <FooComponent />
        </FooContext>
      RUX

      expect(result).to eq("<p>bar</p>")
    end

    it 'uses the default value when no value is provided' do
      result = render(<<~RUX)
        <FooContext>
          <FooComponent />
        </FooContext>
      RUX

      expect(result).to eq("<p>foo</p>")
    end

    it 'calls the default block when provided' do
      result = render(<<~RUX)
        <FooContextWithBlock>
          <FooComponentWithBlock />
        </FooContextWithBlock>
      RUX

      expect(result).to eq("<p>foo from block</p>")
    end

    it 'allows context to be temporarily overridden' do
      result = render(<<~RUX)
        <FooContext value="bar">
          <FooComponent />
          <FooContext value="baz">
            <FooComponent />
          </FooContext>
          <FooComponent />
        </FooContext>
      RUX

      expect(result).to eq("<p>bar</p><p>baz</p><p>bar</p>")
    end
  end
end
