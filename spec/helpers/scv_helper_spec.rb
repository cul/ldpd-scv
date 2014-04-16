require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'catalog_helper'
describe Scv::CatalogHelperBehavior do

  describe "#zoomable?" do
    before(:all) do
      class TestRig
        include Scv::CatalogHelperBehavior
        attr_accessor :resources
        def initialize(resources=[])
          @resources = resources
        end
        def get_resources(document)
          resources()
        end
      end
    end
    after(:all) do
      Object.send(:remove_const, :TestRig)
    end
    it "should return nil when there's no jp2 datastream" do
    end

    it "should return an appropriate file path when there is a managed jp2 datastream" do
      ds = double('zoom')
      ds.stub(:controlGroup).and_return('M')
      ds.stub(:dsCreateDate).and_return(Time.parse('2013-05-25T01:43:20.684Z'))
      ds.stub(:dsid).and_return('zoom')
      ds.stub(:dsLocation).and_return('ldpd:137915+zoom+zoom.0')
      document = {id: 'foo:bar', has_model_ssim: []}.with_indifferent_access
      actual = TestRig.new.zoomable?(document)
      expect(actual).to eql 'file:/foo/2013/0524/21/43/ldpd_137915+zoom+zoom.0'
    end

    it "should return an appropriate file path when there is an external jp2 datastream" do
      ds = double('zoom')
      ds.stub(:controlGroup).and_return('E')
      ds.stub(:dsCreateDate).and_return(Time.parse('2013-05-25T01:43:20.684Z'))
      ds.stub(:dsid).and_return('zoom')
      ds.stub(:dsLocation).and_return('foo')
      document = {id: 'foo:bar', has_model_ssim: []}.with_indifferent_access
      actual = TestRig.new.zoomable?(document)
      expect(actual).to eql 'file:foo'
    end
  end

  describe "#legacy_content_path" do
    before(:all) do
      class TestRig
        include Scv::CatalogHelperBehavior
      end
    end
    after(:all) do
      Object.send(:remove_const, :TestRig)
    end
    it "should work with managed streams" do
      ds = double('RELS-INT')
      ds.stub(:controlGroup).and_return('M')
      ds.stub(:dsCreateDate).and_return(Time.parse('2013-05-25T01:43:20.684Z'))
      ds.stub(:dsid).and_return('RELS-INT')
      ds.stub(:dsLocation).and_return('ldpd:137915+RELS-INT+RELS-INT.0')
      actual = TestRig.new.legacy_content_path(ds)
      expect(actual).to eql '/foo/2013/0524/21/43/ldpd_137915+RELS-INT+RELS-INT.0'
    end
    it "should work with external streams" do
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
