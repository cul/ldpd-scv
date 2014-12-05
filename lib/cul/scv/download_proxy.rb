module Cul::Scv
  class DownloadProxy
    attr_accessor :mime_type, :context, :content_models, :publisher
    def initialize(opts)
      self.mime_type = opts[:mime_type]
      self.context = opts[:context]
      self.content_models = opts[:content_models]
      self.publisher = opts[:publisher]
    end
  end
end