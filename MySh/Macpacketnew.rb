#!/usr/bin/ruby

#puts "Hello, Ruby!你好。";
#puts Dir.pwd #当前工作目录
#puts __FILE__ #rb脚本文件全路径
#puts File.dirname(__FILE__) #rb脚本文件所在目录
if ARGV.empty?
    puts "请传入xml文件路径作为参数."
    exit -1
end
require "rexml/document"
# 定位XML文件中的元素
#子模块分支
SCANLIB_BRANCH = "lp-2023"

xml = REXML::Document.new(File.new(ARGV[0]))
ele_pkgName = xml.root.elements['pkgName']
ele_title = xml.root.elements['title']
ele_easyinstall = xml.root.elements['easyinstall']
ele_targets = xml.root.elements['targets']
ele_project = xml.root.elements['project']
#克隆部分
print <<`EOC`
# 创建工作目录
    cd #{File.dirname(__FILE__)}
    mkdir "#{ele_title.text}"
    cd "#{ele_title.text}"
    rm -Rf build
    mkdir build
    mkdir build/sub_pkgs
    mkdir projects
EOC

# 创建commitID.txt
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    echo "commitID: \n" > ./build/commitID.txt
EOC

# 遍历每个targets
ele_targets.each_element { |element|
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd projects

    # clone代码
    git clone #{element.attributes['git']}
    cd "#{File.basename(element.attributes['git'], '.*')}"
    git checkout .
    git pull
    git submodule update --init --recursive
    git submodule foreach --recursive git checkout #{SCANLIB_BRANCH}

    # 输出commitID.txt
    echo "#{element.attributes['git']} \t `git rev-parse HEAD`" >> ../../build/commitID.txt
EOC
}
# 单独下载一键安装代码
#ele_easyinstall.each_element { |element|
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd projects
    # clone代码
    git clone #{ele_easyinstall.attributes['git']}
    cd #{File.basename(ele_easyinstall.attributes['git'], '.*')}
    git checkout .
    git pull
    git submodule update --init --recursive
    git submodule foreach --recursive git checkout #{SCANLIB_BRANCH}

    # 输出commitID.txt
    echo "#{ele_easyinstall.attributes['git']} \t `git rev-parse HEAD`" >> ../../build/commitID.txt
EOC
#}
#输入编译相关参数
puts "请输入参数是否需要签名、版本号、背景图名称（若打包签名包请查看网络连接）"
tmpstr = STDIN.gets.chomp
ARR = tmpstr.split(' ')
puts ARR.inspect
if ARR[0] != "-s" or ARR[2] != "-v" or ARR[4] != "-i"
    puts "您输入的值错误"
    puts "macosxbuild.rb [XML Path] -s [YES/NO] -v [version] -i [en/zh-Hans]"
    exit
end
# 拼接驱动包名称
if ARR[0] == "-s" and ARR[1] == "YES"
    dmg_string = "#{ele_pkgName.text}" + " V" + ARR[3] + " Codesign"
elsif ARR[0] == "-s" and ARR[1] == "NO"
    dmg_string = "#{ele_pkgName.text}" + " V" + ARR[3]
end
puts "驱动包名称为->#{dmg_string}"
# 判断是否执行签名并对卸载的RootPrivileges执行xcodebuild
if ARR[0] == "-s" and ARR[1] == "YES"
    ele_targets.each_element { |element|
        puts "#{element.text}"
        if element.text.include?"uninstall"
print <<`EOC`
            puts "*****enter uninstall"
            cd #{File.dirname(__FILE__)}
            cd "#{ele_title.text}"
            cd projects/uninstall/RootPrivileges/
            
            rm -Rf build
            xcodebuild clean | xcpretty
            
            xcodebuild -target RootPrivileges -configuration Release \
            ARCHS=x86_64 \
            CLANG_LINK_OBJC_RUNTIME=NO \
            CODE_SIGNING_ALLOWED=YES \
            CODE_SIGN_IDENTITY="Developer ID Application" \
            CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
            CODE_SIGN_STYLE=Manual \
            DEVELOPMENT_TEAM=F7Q64FVDF2 \
            ENABLE_HARDENED_RUNTIME=YES \
            OTHER_CODE_SIGN_FLAGS=--timestamp \
            install | xcpretty
            
            # 拷贝到uninstall/Resources/目录下
            cp build/release/RootPrivileges ../uninstall/Resources/
EOC
end
}
end

# 判断是否执行签名并执行xcodebuild
if ARR[0] == "-s" and ARR[1] == "YES"
    ele_targets.each_element { |element|
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd projects
    cd #{File.basename(element.attributes['git'], '.*')}
    
    rm -Rf build
    xcodebuild clean | xcpretty
    
    xcodebuild -target #{element.text} -configuration Release \
    SDKROOT=macosx10.9 \
    ARCHS=x86_64 \
    CLANG_LINK_OBJC_RUNTIME=NO \
    CODE_SIGNING_ALLOWED=YES\
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=F7Q64FVDF2 \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    install | xcpretty
    
    # 只执行一次xcodebuild，.app文件未写入签名信息
    # 后续优化：再执行一次xcodebuild
    xcodebuild -target #{element.text} -configuration Release \
    SDKROOT=macosx10.9 \
    ARCHS=x86_64 \
    CLANG_LINK_OBJC_RUNTIME=NO \
    CODE_SIGNING_ALLOWED=YES\
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=F7Q64FVDF2 \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    install | xcpretty
    
    # 拷贝到build/sub_pkgs/目录下
    cp build/release/#{element.text}.pkg ../../build/sub_pkgs/
EOC
    }
elsif ARR[0] == "-s" and ARR[1] == "NO"
    ele_targets.each_element { |element|
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd projects
    cd #{File.basename(element.attributes['git'], '.*')}
    
    rm -Rf build
    xcodebuild clean | xcpretty
    
    xcodebuild -target #{element.text} -configuration Release \
    SDKROOT=macosx10.9 \
    ARCHS=x86_64 \
    CLANG_LINK_OBJC_RUNTIME=NO \
    CODE_SIGNING_ALLOWED=NO \
    install | xcpretty
    
    # 拷贝到build/sub_pkgs/目录下
    cp build/release/#{element.text}.pkg ../../build/sub_pkgs/
EOC
}
end

# 根据现在有安装包，使用productbuild --synthesize命令生成distribution.dist
synthesizeCMD = "productbuild --synthesize "
ele_targets.each_element { |element| synthesizeCMD = synthesizeCMD + "--package ./build/sub_pkgs/#{element.text}.pkg "}
synthesizeCMD = synthesizeCMD + "./build/distribution.dist"
puts "#{synthesizeCMD}"
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    #{synthesizeCMD}
EOC

# 处理distribution.dist信息
rb_dir = File.dirname(__FILE__)
dist_path = rb_dir + "/" + ele_title.text + "/build/distribution.dist"
doc = REXML::Document.new(File.open(dist_path))
title = doc.root.add_element('title', nil)
title.add_text ele_title.text
# 添加自定义函数
script = doc.root.add_element('script', nil)
script_func = %Q[
function versionCheck() {
if (system.compareVersions(system.version.ProductVersion, '10.12') >= 0)
return true;
else
return false;
}
]
script_text = REXML::Text.new(script_func, false, nil, true);
script.add_text script_text
# 指定用户是否可以选择引导卷以外的安装卷
options = doc.root.elements['options']
options.attributes['rootVolumeOnly']= 'true'
# 指定安装完成后要执行的操作
doc.root.each_child{ |child|
if child.class == REXML::Element && child.attributes['onConclusion'] && !child.attributes['onConclusion'].empty?
    child.attributes['onConclusion']= 'None'
end
    # 在系统版本高于macOS 10.12时安装
if child.class == REXML::Element && child.attributes['visible'] && child.attributes['id'] && !child.attributes['id'].empty?
    if child.attributes['id'].include? 'com.pantum.USBMonitor'
        child.attributes['selected']= "versionCheck()"
        child.attributes['enabled']= "versionCheck()"
    elsif child.attributes['id'].include? 'com.pantum.MacPushScan'
        child.attributes['selected']= "versionCheck()"
        child.attributes['enabled']= "versionCheck()"
    end
end
}
file = File.new(dist_path,"w+")
file.write doc
file.close

# 使用productbuild --distribution命令生成最终安装包
distributionCMD = "productbuild --distribution ./build/distribution.dist --package-path ./build/sub_pkgs/ ./build/\"#{ele_pkgName.text}.pkg\""
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    #{distributionCMD}
EOC

# 判断pkg是否执行productsign并复制到一键安装
easyInstallurl = File.basename("#{ele_easyinstall.attributes['git']}",".*")
if ARR[0] == "-s" and ARR[1] == "YES"
    productsignCMD = "productsign --timestamp --sign 'Developer ID Installer: Zhuhai Pantum Electronics Co. Ltd. (F7Q64FVDF2)' ./build/\"#{ele_pkgName.text}.pkg\" ./build/Driver.pkg"
#    ele_easyinstall.each_element { |element|
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    #{productsignCMD}

EOC
#}
elsif ARR[0] == "-s" and ARR[1] == "NO"
cpCMD = "cp ./build/\"#{ele_pkgName.text}.pkg\" ./projects/\"#{easyInstallurl}\"/EasyInstall/Resources/#{ele_easyinstall.text}/Driver.pkg"
#    ele_easyintall.each_element { |element|
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    #{cpCMD}
EOC
#}
end
# 编译生成EasyInstall
if ARR[0] == "-s" and ARR[1] == "YES"
#    ele_easyinstall.each_element { |element|
    easyInstallstr = File.basename("#{ele_easyinstall.attributes['git']}",".*")
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
#    cd projects/easyinstall/EasyInstall
    cd projects/"#{easyInstallstr}"/EasyInstall

    rm -Rf build
    xcodebuild clean | xcpretty

    xcodebuild -target #{ele_easyinstall.text} -configuration Release \
    SDKROOT=macosx10.9 \
    MARKETING_VERSION=#{ARR[3]} \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=F7Q64FVDF2 \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    archive | xcpretty

    cp -R ./build/install/EasyInstall.dst/Applications/* ../RootPrivileges/RootPrivileges/Resources/#{ele_easyinstall.text}
EOC
#}
elsif ARR[0] == "-s" and ARR[1] == "NO"
#ele_easyinstall.each_element { |element|
    easyInstallstr = File.basename("#{ele_easyinstall.attributes['git']}",".*")
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
#    cd projects/EasyInstall/EasyInstall
    cd projects/"#{easyInstallstr}"/EasyInstall
    rm -Rf build
    xcodebuild clean | xcpretty
    
    xcodebuild -target #{ele_easyinstall.text} -configuration Release \
    SDKROOT=macosx10.9 \
    MARKETING_VERSION=#{ARR[3]} \
    archive | xcpretty
    
    cp -R ./build/install/EasyInstall.dst/Applications/* ../RootPrivileges/RootPrivileges/Resources/#{ele_easyinstall.text}
EOC
#}
end

# 编译生成RootPrivileges
if ARR[0] == "-s" and ARR[1] == "YES"
#    ele_easyinstall.each_element { |element|
    RootPrivilegesstr = File.basename("#{ele_easyinstall.attributes['git']}",".*")
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
#    cd projects/easyinstall/RootPrivileges
    cd projects/"#{RootPrivilegesstr}"/RootPrivileges
    rm -Rf build
    xcodebuild clean | xcpretty

    xcodebuild -target #{ele_easyinstall.text} -configuration Release \
    SDKROOT=macosx10.9 \
    MARKETING_VERSION=#{ARR[3]} \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=F7Q64FVDF2 \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    archive | xcpretty

    cp -R ./build/install/RootPrivileges.dst/Applications/* ../../../build
EOC
#}
elsif ARR[0] == "-s" and ARR[1] == "NO"
#ele_easyinstall.each_element { |element|
    RootPrivilegesstr = File.basename("#{ele_easyinstall.attributes['git']}",".*")
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
#    cd projects/easyinstall/RootPrivileges
    cd projects/"#{RootPrivilegesstr}"/RootPrivileges
    rm -Rf build
    xcodebuild clean | xcpretty
    
    xcodebuild -target #{ele_easyinstall.text} -configuration Release \
    SDKROOT=macosx10.9 \
    MARKETING_VERSION=#{ARR[3]} \
    archive | xcpretty
    
    cp -R ./build/install/RootPrivileges.dst/Applications/* ../../../build
EOC
#}
end

# 将一键安装放入磁盘工具
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build

    mkdir pkgFolder
    mkdir pkgFolder/.background
    mv "Pantum Install Tool.app" ./pkgFolder
    cp "../../Resources/#{ARR[5]}.png" "./pkgFolder/.background"

    hdiutil create -srcfolder "pkgFolder"  -volname "#{dmg_string}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100000k "pack.temp.dmg"
EOC

dev_string =  <<`dev`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build
    hdiutil attach -readwrite -noverify -noautoopen "pack.temp.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}'
dev

# 设置磁盘工具内部的样式
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build

    echo '
    tell application "Finder"
    tell disk "#{dmg_string}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {0, 0, 780, 480}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 128
    set background picture of theViewOptions to file ".background:#{ARR[5]}.png"
    set position of item "Pantum Install Tool.app" of container window to {390, 180}
    close
    open
    update without registering applications
    delay 10
    close
    end tell
    end tell
    ' | osascript
EOC

print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build

    chmod -Rf go-w /Volumes/"#{dmg_string}"
    sync
    hdiutil detach #{dev_string}

    hdiutil convert "./pack.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "#{dmg_string}.dmg"
    rm -f ./pack.temp.dmg
EOC

# 判断是否执行签名
if ARR[0] == "-s" and ARR[1] == "YES"
    codesignCMD = "codesign --force --deep --timestamp --options runtime --sign 'Developer ID Application: Zhuhai Pantum Electronics Co. Ltd. (F7Q64FVDF2)' \"#{dmg_string}.dmg\""
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build
    #{codesignCMD}
EOC
#输入编译相关参数
    puts "请输入认证所需的参数id（唯一）"
    signingstr = STDIN.gets.chomp
    signingID = "xcrun notarytool store-credentials \"#{signingstr}\" --apple-id \"hdc@pantum.com\" --team-id \"F7Q64FVDF2\" --password \"kfkm-zhfa-hxsc-exgh\""
    submit = "xcrun notarytool submit \"#{dmg_string}.dmg\" --keychain-profile \"#{signingstr}\" --wait"
        puts signingID
        puts submit
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build
    #{signingID}
    #{submit}
EOC
end
print <<`EOC`
    cd #{File.dirname(__FILE__)}
    cd "#{ele_title.text}"
    cd build
    mkdir -p ~/Desktop/release/#{ele_project.text}/#{ele_easyinstall.text}
    cp "#{dmg_string}.dmg" ~/Desktop/release/#{ele_project.text}/#{ele_easyinstall.text}
EOC

