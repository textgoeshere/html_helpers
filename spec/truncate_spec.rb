require File.dirname(__FILE__) + '/spec_helper'

require File.join(File.dirname(__FILE__), '..', 'lib', 'truncate')
include HTMLHelper

# NOTE: Nokogiri automatically inserts line breaks which makes testing String output more fragile 
#   because the line breaks have to be stripped or accounted for
# TODO: remove this fragility
class String
  def flatten!
    gsub(/\n/, '')
  end
end

class Nokogiri::XML::NodeSet
  def to_flat_s
    to_s.flatten!
  end
end

TEST_HTML="<div><p>Hello there.</p>&nbsp;<p>Goodbye now!</p></div>"
OPTIONS = {
    :length         => 30,
    :break_on_work  => false,
    :omission       => '...',
    :coda           => nil,
    :log            => false
}

describe NokogiriTruncator do
  before :each do 
    @doc = Nokogiri::HTML.fragment(TEST_HTML) 
  end
  
  it "should return doc unchanged when text content of doc is shorter than length and there's no coda" do
    @doc.truncate(@doc.text_length + 1, OPTIONS).should eql(@doc)
  end
  
  it "should return well-formed html snippet with no open tags if truncating in the middle of an element" do
    @doc.truncate(5, OPTIONS).children.to_flat_s.should eql("<div><p>Hello...</p></div>")
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
      truncate_html(@html, :coda => '').flatten!.should eql(@html)
    end
    
    it "should include coda if coda is not blank" do
      coda = "foo"
      truncate_html(@html, :coda => coda).flatten!.should match(Regexp.new(coda))
    end
    
    it "should have coda "
    
    
    
    it " - even if (text plus omission) is longer than text - should not append omission" do
      truncate_html(@html, :length => @doc.text_length).flatten!.should eql(@html)
    end
  end
  
  it "should insert omission at bottom of last child element" do
    truncate_html(@html, :length => 5, :log => true).flatten!.should eql("<div><p>He...</p></div>")
  end
  
  
  
  
end
