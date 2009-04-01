# = Credits
#
# By Henrik Nyh <http://henrik.nyh.se> 2008-01-30.
# Free to modify and redistribute with credit.
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

require "rubygems"
gem "nokogiri"
gem "activesupport"
require 'nokogiri'
require 'activesupport'

module HtmlHelper

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
  # - +coda+ -          String inserted at the bottom of the parent element of truncated +text+ whether it is actually truncated or not (default: nil)          
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
    
    options = args.extract_options!
    length        = options[:length]        || 30
    omission      = options[:omission]      || '...'
    break_on_word = options[:break_on_word] || false
    coda          = options[:coda]          || nil
    
    doc = text.respond_to?(:inner_text) ? text : Nokogiri::HTML.fragment(text.to_s)
    omission_length = Nokogiri::HTML.fragment(omission).text_length
    text_length = doc.text_length
    actual_length = length - omission_length

    if text_length > length
      truncated_doc = doc.truncate(actual_length)
      
      if break_on_word
        word_length = actual_length - (truncated_doc.text_length - truncated_doc.inner_html.rindex(' '))
        truncated_doc = doc.truncate(word_length).child
      end

      last_child = truncated_doc.children.last
      if last_child.inner_html.nil?
        truncated_doc.inner_html + omission + coda if coda
      else        
        last_child.inner_html = last_child.inner_html.gsub(/\W.[^\s]+$/, "") + omission
        last_child.inner_html += coda if coda
        truncated_doc
      end
    else 
      unless coda.blank?
        last_child = doc.children.last
        if last_child.inner_html.nil?
          doc.inner_html + coda
        else
          last_child.inner_html = last_child.inner_html.gsub(/\W.[^\s]+$/, "") + coda
          doc
        end      
      else
        text
      end
    end
  end


end

module NokogiriTruncator
  module NodeWithChildren
    def text_length
      self.text.mb_chars.length
    end
    
    def truncate(length, log = false)
      return self if text_length <= length
      
      truncated_node = self.dup
      truncated_node.children.remove
      
      self.children.each do |node|
        remaining_length = length - truncated_node.text_length
        break if remaining_length == 0
        truncated_node << node.truncate(remaining_length)
      end
      truncated_node
    end
  end

  module TextNode
    def truncate(length)
      self.content = content.mb_chars[0...length] 
      self
    end  
  end

  module IgnoredTag
    def truncate(length)
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
