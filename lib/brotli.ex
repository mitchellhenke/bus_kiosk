defmodule Phoenix.Digester.Brotli do
  @behaviour Phoenix.Digester.Compressor
  def compress(content) do
    :brotli.encode(content)
  end

  def file_extension do
    ".br"
  end

  def compress_file?(file_path, _content, _digested_content) do
    Path.extname(file_path) in Application.fetch_env!(:phoenix, :gzippable_exts)
  end
end
