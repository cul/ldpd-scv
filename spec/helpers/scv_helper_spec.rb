require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'catalog_helper'
describe Scv::CatalogHelperBehavior do
	before do
    class TestRig
      include Scv::CatalogHelperBehavior
    end
  end

  describe "#zoomable?" do
    it "should return nil when there's no jp2 datastream" do
    end

    it "should return an appropriate file path when there is a jp2 datastream" do
    end
  end

  describe "#legacy_content_path" do
    it "should work with managed streams" do
      ds = double('RELS-INT')
      ds.stub(:controlGroup).and_return('M')
      ds.stub(:dsCreateDate).and_return(Time.parse('2013-05-25T01:43:20.684Z'))
      ds.stub(:dsid).and_return('RELS-INT')
      ds.stub(:dsLocation).and_return('ldpd_137915+RELS-INT+RELS-INT.0')
      actual = TestRig.new.legacy_content_path(ds)
      expect(actual).to eql '/foo/2013/0524/21/43/ldpd_137915+RELS-INT+RELS-INT.0'
    end
    it "should work with external streams" do
      input = Time.parse('2013-05-25T01:43:20.684Z')
      ds = double('RELS-INT')
      ds.stub(:controlGroup).and_return('E')
      ds.stub(:dsCreateDate).and_return(Time.parse('2013-05-25T01:43:20.684Z'))
      ds.stub(:dsid).and_return('RELS-INT')
      ds.stub(:dsLocation).and_return('foo')
      actual = TestRig.new.legacy_content_path(ds)
      expect(actual).to eql 'foo'
    end
  end
  
end
