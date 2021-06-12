require 'cgi'

module Rux
  class DefaultVisitor < Visitor
    def visit_list(node, &block)
      node.children.each { |child| visit(child, &block) }
    end

    def visit_ruby(node, &block)
      node.tokens.each(&block)
    end

    def visit_string(node, &block)
      yield [:tSTRING, [node.str, node.pos]]
    end

    def visit_tag(node, &block)
      if node.name.start_with?(/[A-Z]/)
        yield [:tIDENTIFIER, ['render']]
        yield [:tLPAREN2,    ['(']]
        yield [:tCONSTANT,   [node.name, node.pos]]
        yield [:tDOT,        ['.']]
        yield [:tIDENTIFIER, ['new']]

        unless node.attrs.empty?
          yield [:tLPAREN2, ['(']]
          emit_attrs(node, &block)
        end
      else
        yield [:tCONSTANT,   ['Rux']]
        yield [:tDOT,        ['.']]
        yield [:tIDENTIFIER, ['tag']]
        yield [:tLPAREN2,    ['(']]
        yield [:tSTRING,     [node.name, node.pos]]

        unless node.attrs.empty?
          yield [:tCOMMA, [',']]
          emit_attrs(node, &block)
        end
      end

      yield [:tRPAREN, [')']]

      if node.children.size > 1
        yield [:tLCURLY, ['{']]
        emit_block_arg(node, &block)

        yield [:tCONSTANT,   ['Rux']]
        yield [:tDOT,        ['.']]
        yield [:tIDENTIFIER, ['create_buffer']]
        yield [:tDOT,        ['.']]
        yield [:tIDENTIFIER, ['tap']]
        yield [:tLCURLY,     ['{']]
        yield [:tPIPE,       ['|']]
        yield [:tIDENTIFIER, ['_rux_buf_']]
        yield [:tPIPE,       ['|']]

        node.children.each do |child|
          yield [:tIDENTIFIER, ['_rux_buf_']]
          yield [:tLSHFT,      ['<<']]
          visit(child, &block)
          yield [:tSEMI,       [';']]
        end

        yield [:tRCURLY,     ['}']]
        yield [:tDOT,        ['.']]
        yield [:tIDENTIFIER, ['to_s']]
        yield [:tRCURLY,     ['}']]
      elsif node.children.size == 1
        yield [:tLCURLY, ['{']]
        emit_block_arg(node, &block)
        visit(node.children.first, &block)
        yield [:tRCURLY, ['}']]
      end
    end

    def visit_text(node, &block)
      yield [:tSTRING, ["#{CGI.escape_html(node.text)}", node.pos]]
    end

    private

    def emit_attrs(node, &block)
      idx = 0

      node.attrs.each do |attribute|
        next if attribute.name == 'as'

        yield [:tCOMMA, [',']] if idx > 0
        yield [:tLABEL, [attribute.name.gsub('-', '_'), attribute.name_pos]]
        visit(attribute.value, &block)
        idx += 1
      end
    end

    def emit_block_arg(node, &block)
      as_attr = node.attrs.find { |a| a.name == 'as' }

      if as_attr
        yield [:tPIPE, ['|']]
        visit(as_attr.value, &block)
        yield [:tPIPE, ['|']]
      end
    end
  end
end
