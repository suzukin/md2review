# coding: UTF-8
rootdir = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{rootdir}/lib"

if defined? Encoding
  Encoding.default_internal = 'UTF-8'
end

require 'test/unit'
require 'redcarpet'
require 'redcarpet/render/review'

class ReVIEWTest < Test::Unit::TestCase

  def setup
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::ReVIEW.new({}))
  end

  def render_with(flags, text, render_flags = {})
    renderer = Redcarpet::Render::ReVIEW.new(render_flags)
    Redcarpet::Markdown.new(renderer, flags).render(text)
  end

  def test_that_simple_one_liner_goes_to_review
    assert_respond_to @markdown, :render
    assert_equal "\n\nHello World.\n\n", @markdown.render("Hello World.\n")
  end

  def test_href
    assert_respond_to @markdown, :render
    assert_equal "\n\n@<href>{http://exmaple.com,example}\n\n", @markdown.render("[example](http://exmaple.com)\n")
  end

  def test_href_with_comma
    assert_respond_to @markdown, :render
    assert_equal "\n\n@<href>{http://exmaple.com/foo\\,bar,example}\n\n", @markdown.render("[example](http://exmaple.com/foo,bar)")
  end

  def test_href_in_footnote
    text = %Q[aaa [foo](http://example.jp/foo), [bar](http://example.jp/bar), [foo2](http://example.jp/foo)]
    rd = Redcarpet::Markdown.new(Redcarpet::Render::ReVIEW.new({:link_in_footnote => true})).render(text)
    assert_equal %Q|\n\naaa foo@<fn>{3ccd7167b80081c737b749ad1c27dcdc}, bar@<fn>{9dcab303478e38d32d83ae19daaea9f6}, foo2@<fn>{3ccd7167b80081c737b749ad1c27dcdc}\n\n\n//footnote[3ccd7167b80081c737b749ad1c27dcdc][http://example.jp/foo]\n\n//footnote[9dcab303478e38d32d83ae19daaea9f6][http://example.jp/bar]\n|, rd
  end

  def test_href_with_emphasised_anchor
    assert_equal "\n\n@<href>{http://exmaple.com/,example}\n\n", @markdown.render("[*example*](http://exmaple.com/)")
  end

  def test_href_with_double_emphasised_anchor
    assert_equal "\n\n@<href>{http://exmaple.com/,example}\n\n", @markdown.render("[**example**](http://exmaple.com/)")
  end

  def test_href_with_codespan_anchor
    assert_equal "\n\n@<href>{http://exmaple.com/,example}\n\n", @markdown.render("[`example`](http://exmaple.com/)")
  end

  def test_emphasis_with_href
    assert_respond_to @markdown, :render
    assert_equal "\n\n@<b>{{hello\\} }@<href>{http://exmaple.com/foo\\,bar,example}@<b>{ world}\n\n", @markdown.render("*{hello} [example](http://exmaple.com/foo,bar) world*")
  end

  def test_header
    assert_respond_to @markdown, :render
    assert_equal "\n= AAA\n\n\nBBB\n\n\n== ccc\n\n\nddd\n\n", @markdown.render("#AAA\nBBB\n\n##ccc\n\nddd\n")
  end

  def test_header56
    assert_respond_to @markdown, :render
    assert_equal "\n===== AAA\n\n\nBBB\n\n\n====== ccc\n\n\nddd\n\n", @markdown.render("#####AAA\nBBB\n\n######ccc\n\nddd\n")
  end

  def test_header_attributes
    assert_respond_to @markdown, :render
    assert_equal "\n\#@# header_attribute: {-}\n= AAA\n\n\#@# header_attribute: {\#foo .bar title=hoge}\n= BBB\n", @markdown.render("\#AAA  {-}\n\n\#BBB {\#foo .bar title=hoge}\n\n")
  end

  def test_header_attributes_without_space
    assert_respond_to @markdown, :render
    assert_equal "\n\#@# header_attribute: {-}\n= AAA\n\n\= BBB@<tt>{test}\n",
                 @markdown.render("\#AAA  {-}\n\n\#BBB@<tt>{test}\n\n")
  end

  def test_image
    assert_equal "\n\n//image[image][test]{\n//}\n\n\n", @markdown.render("![test](path/to/image.jpg)\n")
  end

  def test_indented_image
    assert_equal "\n\n//image[image][test]{\n//}\n\n\n", @markdown.render(" ![test](path/to/image.jpg)\n")
  end

  def test_indepimage
    rev = render_with({}, "![test](path/to/image.jpg)\n",{:disable_image_caption => true})
    assert_equal "\n\n//indepimage[image]\n\n\n", rev
  end

  def test_nested_ulist
    assert_equal " * aaa\n ** bbb\n * ccc\n", @markdown.render("- aaa\n  - bbb\n- ccc\n")
  end

  def test_olist
    assert_equal " 1. aaa\n 1. bbb\n 1. ccc\n", @markdown.render("1. aaa\n2. bbb\n3. ccc\n")
  end

  def test_nested_olist
    ## XXX not support yet in Re:VIEW
    assert_equal " 1. aaa\n 1. bbb\n 1. ccc\n", @markdown.render("1. aaa\n   2. bbb\n3. ccc\n")
  end

  def test_olist_image
    assert_equal " 1. aaa@<icon>{foo}\n 1. bbb\n 1. ccc\n", @markdown.render("1. aaa\n    ![test](foo.jpg)\n2. bbb\n3. ccc\n")
  end

  def test_olist_image2
    assert_equal " 1. aaa@<br>{}@<icon>{foo}\n 1. bbb\n 1. ccc\n", @markdown.render("1. aaa  \n    ![test](foo.jpg)\n2. bbb\n3. ccc\n")
  end

  def test_table_with_empty_cell
    rd = render_with({:tables => true}, %Q[\n\n| a  |  b |  c |\n|----|----|----|\n| A  | B  | C  |\n|    | B  |  C |\n| .A | B  |  C |\n\n])
    assert_equal "//table[tbl1][]{\na\tb\tc\n-----------------\nA\tB\tC\n.\tB\tC\n..A\tB\tC\n//}\n", rd
  end

  def test_code_fence_with_caption
    rd = render_with({:fenced_code_blocks => true}, %Q[~~~ {caption="test"}\ndef foo\n  p "test"\nend\n~~~\n])
    assert_equal %Q[\n//emlist[test]{\ndef foo\n  p "test"\nend\n//}\n], rd
  end

  def test_code_fence_without_flag
    rd = render_with({}, %Q[~~~ {caption="test"}\ndef foo\n  p "test"\nend\n~~~\n])
    assert_equal %Q[\n\n~~~ {caption="test"}\ndef foo\n  p "test"\nend\n~~~\n\n], rd
  end

  def test_code_fence_with_lang
    rd = render_with({:fenced_code_blocks => true}, %Q[~~~ruby\ndef foo\n  p "test"\nend\n~~~\n])
    assert_equal %Q[\n//emlist[][ruby]{\ndef foo\n  p "test"\nend\n//}\n], rd
  end

  def test_code_fence_with_console
    rd = render_with({:fenced_code_blocks => true}, %Q[~~~console\ndef foo\n  p "test"\nend\n~~~\n])
    assert_equal %Q[\n//emlist[][console]{\ndef foo\n  p "test"\nend\n//}\n], rd
    rd = render_with({:fenced_code_blocks => true},
                      %Q[~~~console\ndef foo\n  p "test"\nend\n~~~\n],
                     {:enable_cmd => true})
    assert_equal %Q[\n//cmd{\ndef foo\n  p "test"\nend\n//}\n], rd
  end

  def test_group_ruby
    rd = render_with({:ruby => true}, "{電子出版|でんししゅっぱん}を手軽に\n")
    assert_equal %Q[\n\n@<ruby>{電子出版,でんししゅっぱん}を手軽に\n\n], rd
  end

  def test_tcy
    rd = render_with({:tcy => true}, "昭和^53^年\n")
    assert_equal %Q[\n\n昭和@<tcy>{53}年\n\n], rd
  end

  def test_footnote
    rd = render_with({:footnotes=>true}, "これは*脚注*付き[^1]の段落です。\n\n\n[^1]: そして、これが脚注です。\n")
    assert_equal %Q|\n\nこれは@<b>{脚注}付き@<fn>{1}の段落です。\n\n\n//footnote[1][そして、これが脚注です。]\n|, rd
  end
end
