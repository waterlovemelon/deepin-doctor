#ifndef EXAMPLE_PLUGIN_H
#define EXAMPLE_PLUGIN_H

#include "PluginInterface.h"

namespace DeepinDoctor {

/**
 * @brief 示例插件类
 *
 * 这个插件展示了如何开发一个deepin-doctor插件。
 * 功能：收集用户最近打开的文件记录。
 */
class ExamplePlugin : public QObject, public PluginInterface
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.deepin.Doctor.PluginInterface/1.0")
    Q_INTERFACES(DeepinDoctor::PluginInterface)

public:
    ExamplePlugin();
    ~ExamplePlugin() override;

    // PluginInterface interface
    QString id() const override;
    ModuleInterface* createModule() override;
};

} // namespace DeepinDoctor

#endif // EXAMPLE_PLUGIN_H
