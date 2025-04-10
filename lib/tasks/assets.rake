namespace :assets do
  desc "Clear JavaScript cache in development mode"
  task clobber_js: :environment do
    puts "Clearing JavaScript cache..."
    FileUtils.rm_rf(Dir.glob(Rails.root.join("tmp", "cache", "assets", "**", "*.js")))
    FileUtils.rm_rf(Dir.glob(Rails.root.join("public", "assets", "**", "*.js")))
    FileUtils.rm_rf(Dir.glob(Rails.root.join("public", "packs", "**", "*.js")))
    puts "JavaScript cache cleared!"
  end
end
