require File.dirname(__FILE__) + '/spec_helper'

require File.join(File.dirname(__FILE__), '..', 'lib', 'truncate')
include HTMLHelper

puts ("\n" * 15)

TEST_HTML = "<div><p>Hello there.</p>&nbsp;<p>Goodbye now!</p></div>"

describe NokogiriTruncator do
  before :each do 
    @doc = Nokogiri::HTML.fragment(TEST_HTML) 
  end
  
  it "should return doc unchanged when text content of doc is shorter than length" do
    @doc.truncate(@doc.text_length + 1).should eql(@doc)
  end
  
  it "should return well-formed html snippet with no open tags if truncating in the middle of an element" do
    @doc.truncate(5, true).children.to_s.should eql("<div><p>Hello</p></div>")
  end
end

describe "HtmlHelper#truncate_html" do
  before :each do
    @html = TEST_HTML
    @doc = Nokogiri::HTML.fragment(@html)
  end
  
  #
  #
  describe "in general" do
    it "should accept a string snippet of html" do
      lambda { truncate_html(@html) }.should_not raise_error
    end
    
    it "should return a string of html when given a string snippet of html" do
      truncate_html(@html).class.should eql(String)
    end
    
    it "should accept a Nokogiri XML Nodeset" do
      lambda { truncate_html(@doc) }.should_not raise_error
    end
    
    it "should return a Nokogiri XML Nodeset when given a Nokogiri XML Nodeset" do
      truncate_html(@doc).class.should eql(Nokogiri::XML::NodeSet)
    end
    
    it "should return nil when text is nil" do
      truncate_html(nil).should be_nil
    end
    
    it "should return an empty string when text is empty string" do
      truncate_html('').should eql('')
    end
  end
  
  #
  #
  describe "when text is shorter than length" do
    it "and coda is blank, should return original snippet unchanged" do
      truncate_html(@doc, :coda => '').to_s.should eql(@doc.children.to_s)
    end
    
    it "should insert coda at bottom of parent element" do
      coda = "foo"
      truncate_html(@doc, :coda => "foo").to_s.should eql("<div><p>Hello there.</p>&nbsp;<p>Goodbye now!<p>#{coda}</div>")
    end
    
    it " - even if (text plus omission) is longer than text - should not append omission" do
      truncate_html(@doc, :length => @doc.text_length).to_s.should eql(@doc.children.to_s)
    end
  end
  
  it "should insert omission at bottom of last child element" do
    truncate_html(@doc, :length => @doc.text_length - 5).should eql("<div><p>...</p></div>")
  end
end
