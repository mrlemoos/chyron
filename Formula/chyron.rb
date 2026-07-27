class Chyron < Formula
  desc "Claude Code status line showing context-window usage"
  homepage "https://github.com/mrlemoos/chyron"
  url "https://github.com/mrlemoos/chyron/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "fe933506bc456a556280cb14d50154b5750cbc9fb0d72d8877ed7ff2d30438a9"
  license "MIT"

  depends_on "jq"

  def install
    bin.install "chyron.sh" => "chyron"
  end

  def caveats
    <<~EOS
      Point Claude Code at chyron in ~/.claude/settings.json:
        "statusLine": { "type": "command", "command": "#{opt_bin}/chyron" }
      Then restart Claude Code (or run /statusline).
    EOS
  end

  test do
    t = testpath/"t.jsonl"
    t.write '{"type":"assistant","isSidechain":false,"message":{"usage":{"input_tokens":100000}}}'
    assert_match "tok", pipe_output("#{bin}/chyron", %({"transcript_path":"#{t}"}))
  end
end
