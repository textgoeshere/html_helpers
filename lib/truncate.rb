# = Credits
#
# Original script by Henrik Nyh <http://henrik.nyh.se> 2008-01-30.
#
# Modified by Dave Nolan <http://textgoeshere.org.uk> 2008-02-06
# - Ellipsis appended to text of last HTML node
# - Ellipsis inserted after final word break
#
# Modified by Mark Dickson <mark AT sitesteaders.com> 2008-12-18
# - Option to truncate to last full word
# - Option to include a 'more' link
# - Check for nil last child
#
# Modified by Dave Nolan <http://textgoeshere.org.uk> 2009-04-01
# - Added RDOC
# - Added tests
# - Improved compatibility with <code>ActionView::Helpers::TextHelper#truncate</code>
# - Tweaked link, words options
# - Fixed some ActiveSupport deprecations
# - Changed to Nokogiri from Hpricot

gem "nokogiri"
gem "activesupport"
require 'nokogiri'
require 'activesupport'

module HTMLHelper

  # HTML-safe truncation.
  #
  # Returns a given +text+ truncated after a given +length+ if +text+ is longer than +length+ (defaults to 30).
  # The last characters will be replaced with +ommission+.
  #
  # It's just like the Rails _truncate_ helper but doesn't break HTML tags, entities, and optionally, words. If it splits in the middle of an element, 
  # it closes all open tags.
  #
  # === Arguments
  # - +text+ -          Either a string or an Hpricot Doc (efficient if you want to preprocess HTML before truncating).
  #
  # === Options
  # - +length+ -        Maximum total length of truncated +text+ (default: 30). 
  # - +ommission+ -     Ellipsis, only present if +text+ has actually been truncated, inserted at bottom of the last child element (default: '...').
  # - +break_on_word+ - +true+ to ensure that +text+ is truncated on a word boundary. 
  #   Note this may mean that the length of the truncated text returned is less than +length+ (default +false+)
  # - +coda+ -          String inserted at the bottom of the parent element of truncated +text+ whether it is actually truncated or not (default: nil).
  #   This is useful if you can rely that your fragment root element will always be the same, and you want to add, say, a "read on" link inside at the bottom.
  #
  # === Examples
  #   truncate '<p>Hello, my name is Danbert</p>' 
  #   #=> '<p>Hello, my name is Danbert</p>'
  #            
  #   truncate '<p>Hello, my name is Danbert</p>', :length => 15 
  #   #=> '<p>Hello, my na...</p>'
  #            
  #   truncate '<p>Hello, my name is Danbert</p>', :length => 15, :break_on_word => true 
  #   #=> '<p>Hello, my...</p>'
  #            
  #   truncate '<div><p>Hello, my name is Danbert</p></div>', :coda => link_to('More', user_path(@user))
  #   #=> '<div><p>Hello, my name is Danbert</p><a href="/users/1">More</a></div>'
  #
  #   truncate '<div><p>Hello, my name is Danbert</p></div>', :length => 15, :coda => link_to('More', user_path(@user)) 
  #   #=> '<div><p>Hello, my na...</p><a href="/users/1">More</a></div>'
  #
  def truncate_html(text, *args)
    return text if text.blank?
    
    options = args.extract_options!.reverse_merge({
        :length         => 30,
        :break_on_work  => false,
        :omission       => '...',
        :coda           => nil,
        :log            => false
    })
    
    already_parsed = text.respond_to?(:children)
    doc = already_parsed ? text : Nokogiri::HTML.fragment(text.to_s)
    
    if doc.text_length > options[:length]
      actual_length = options[:length] - options[:omission].mb_chars.length
      new_doc = doc.truncate(actual_length, options)
    else
      new_doc = doc.dup
    end
    
    unless options[:coda].blank?
      coda_node = Nokogiri::XML::Text.new(options[:coda], new_doc.document)
      new_doc.children.last << coda_node
    end
    
    # Return what was were passed, a String for a String, a NodeSet for a Nodeset
    already_parsed ? new_doc.children : new_doc.children.to_s
  end
end

module NokogiriTruncator
  module NodeWithChildren
    def text_length
      self.text.mb_chars.length
    end
    
    def truncate(length, options)
      return self if text_length <= length
      
      truncated_node = self.dup
      truncated_node.children.remove
      
      self.children.each do |node|
        remaining_length = length - truncated_node.text_length
        break if remaining_length <= 0
        truncated_node << node.truncate(remaining_length, options)
      end
      truncated_node
    end
  end

  module TextNode
    def truncate(length, options)
      content_length = content.mb_chars.length
      self.content = content.mb_chars[0...length]
      self.content += options[:omission] if content_length > length 
      self
    end  
  end

  module IgnoredTag
    def truncate(length, options)
      self
    end
  end
end

Nokogiri::XML::Document.send(:include, NokogiriTruncator::NodeWithChildren)
Nokogiri::XML::DocumentFragment.send(:include, NokogiriTruncator::NodeWithChildren)
Nokogiri::XML::Element.send(:include,   NokogiriTruncator::NodeWithChildren)
Nokogiri::XML::Text.send(:include,      NokogiriTruncator::TextNode)
Nokogiri::XML::CDATA.send(:include,     NokogiriTruncator::IgnoredTag)
Nokogiri::XML::Comment.send(:include,   NokogiriTruncator::IgnoredTag)
