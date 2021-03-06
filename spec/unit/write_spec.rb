# frozen_string_literal: true

RSpec.describe TTY::Config, "#write", type: :sandbox do
  it "writes configuration to a specified file" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: ["BTC", "TRX", "DASH"])
    file = "config.yml"

    config.write(file)

    expect(::File.read(file)).to eq <<-EOS
---
settings:
  base: USD
  exchange: CCCAGG
coins:
- BTC
- TRX
- DASH
    EOS
  end

  it "writes by default to the current directory" do
    config = TTY::Config.new
    config.set("settings", "base", value: "USD")
    config.set("settings", "exchange", value: "CCCAGG")
    config.set("coins", value: ["BTC", "TRX", "DASH"])

    config.write

    expect(::File.read("config.yml")).to eq <<-EOS
---
settings:
  base: USD
  exchange: CCCAGG
coins:
- BTC
- TRX
- DASH
    EOS
  end

  it "doesn't override already existing file" do
    config = TTY::Config.new
    config.set("settings", "base", value: "USD")
    file = "config.yml"

    config.write(file)

    expect {
      config.write(file)
    }.to raise_error(TTY::Config::WriteError,
      "File `#{file}` already exists. Use :force option to overwrite.")
  end

  it "allows to overwrite already existing file" do
    config = TTY::Config.new
    config.set("settings", "base", value: "USD")
    file = "config.yml"

    config.write(file)

    config.write(file, force: true)
  end

  it "writes json format" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: ["BTC", "TRX", "DASH"])
    file = "config.json"

    config.write(file)

    expect(config.extname).to eq(".json")
    expect(::File.read(file)).to eq <<-EOS.chomp
{
  "settings": {
    "base": "USD",
    "exchange": "CCCAGG"
  },
  "coins": [
    "BTC",
    "TRX",
    "DASH"
  ]
}
EOS
  end

  it "writes toml format and assigns default filename and extension" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: ["BTC", "TRX", "DASH"])
    file = "investments.toml"

    config.write(file)

    expect(config.filename).to eq("investments")
    expect(config.extname).to eq(".toml")
    expect(::File.read(file)).to eq <<-EOS
coins = ["BTC","TRX","DASH"]

[settings]
base = "USD"
exchange = "CCCAGG"
EOS
  end

  it "allows to change default file extension" do
    config = TTY::Config.new
    config.filename = "investments"
    config.extname = ".toml"
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: ["BTC", "TRX", "DASH"])

    config.write

    expect(::File.read("investments.toml")).to eq <<-EOS
coins = ["BTC","TRX","DASH"]

[settings]
base = "USD"
exchange = "CCCAGG"
EOS
  end

  it "writes ini format and assigns default filename and extension" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: "BTC,TRX,DASH")
    file = "investments.ini"

    config.write(file)

    expect(config.filename).to eq("investments")
    expect(config.extname).to eq(".ini")
    expect(::File.read(file)).to eq <<-EOS
coins = BTC,TRX,DASH

[settings]
base = USD
exchange = CCCAGG
EOS
  end

  it "writes hcl format and assigns default filename and extension" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :color, value: true)
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: %w[BTC TRX DASH])
    file = "investments.hcl"

    config.write(file)

    expect(config.filename).to eq("investments")
    expect(config.extname).to eq(".hcl")
    expect(::File.read(file)).to eq <<-EOS.chomp
settings {
  base = "USD"
  color = true
  exchange = "CCCAGG"
}
coins = ["BTC", "TRX", "DASH"]
EOS
  end

  it "writes java properties format and assigns default filename and extension" do
    config = TTY::Config.new
    config.set(:base, value: "USD")
    config.set(:color, value: true)
    config.set(:exchange, value: "CCCAGG")
    config.set(:coins, value: "BTC,TRX,DASH")
    file = "investments.props"

    config.write(file)

    expect(config.filename).to eq("investments")
    expect(config.extname).to eq(".props")
    expect(::File.read(file)).to eq <<-EOS.chomp
base=USD
color=true
exchange=CCCAGG
coins=BTC,TRX,DASH
EOS
  end

  it "writes custom format with custom file extension" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    config.set(:settings, :exchange, value: "CCCAGG")
    config.set(:coins, value: ["BTC", "TRX", "DASH"])
    file = "investments.conf"

    config.write(file, format: :yaml)
    expect(config.filename).to eq("investments")
    expect(config.extname).to eq(".conf")
    expect(::File.read(file)).to eq <<-EOS
---
settings:
  base: USD
  exchange: CCCAGG
coins:
- BTC
- TRX
- DASH
EOS
  end

  it "cannot write unknown file format" do
    config = TTY::Config.new
    config.set(:settings, :base, value: "USD")
    file = "config.txt"

    expect {
      config.write(file)
    }.to raise_error(TTY::Config::UnsupportedExtError,
                    "Config file format `.txt` is not supported.")
  end

  it "fails to load dependency for writing file format" do
    allow(TTY::Config::Marshallers::YAMLMarshaller).
      to receive(:require).with("yaml").and_raise(LoadError)

    config = TTY::Config.new
    file = "investments.yml"

    expect {
      config.write(file)
    }.to raise_error(TTY::Config::DependencyLoadError, /The dependency `yaml` is missing/)
  end
end
