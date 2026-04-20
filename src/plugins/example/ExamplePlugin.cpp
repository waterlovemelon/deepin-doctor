#include "ExamplePlugin.h"
#include "ExampleModule.h"

namespace DeepinDoctor {

ExamplePlugin::ExamplePlugin()
{
}

ExamplePlugin::~ExamplePlugin()
{
}

QString ExamplePlugin::id() const
{
    // 插件唯一标识符，建议使用反向域名格式
    return "com.deepin.doctor.plugin.example";
}

ModuleInterface* ExamplePlugin::createModule()
{
    // 创建并返回模块实例
    // 调用者负责删除返回的实例
    return new ExampleModule();
}

} // namespace DeepinDoctor
