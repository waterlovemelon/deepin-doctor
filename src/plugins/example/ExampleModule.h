#ifndef EXAMPLE_MODULE_H
#define EXAMPLE_MODULE_H

#include "ModuleInterface.h"
#include <QAtomicInt>

namespace DeepinDoctor {

/**
 * @brief 示例模块类
 *
 * 这个模块演示了如何实现ModuleInterface接口。
 * 功能：
 * - 收集用户最近打开的文件记录
 * - 检测是否存在异常文件访问模式
 */
class ExampleModule : public ModuleInterface
{
public:
    ExampleModule();
    ~ExampleModule() override;

    // ModuleInterface interface
    QString name() const override;
    QString description() const override;
    QString version() const override;

    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;

    float progress() const override;
    void cancel() override;
    bool isRunning() const override;

    int timeout() const override { return 60; } // 设置超时为60秒

private:
    // 收集最近打开文件记录
    void collectRecentlyOpenedFiles(QJsonObject& result);

    // 收集特定应用的访问日志
    void collectApplicationLogs(QJsonObject& result);

    // 检查是否有异常访问模式
    QList<Issue> checkForAbnormalPatterns(const QJsonObject& collectedData);

    // 进度和状态管理
    QAtomicInt m_running;
    QAtomicInt m_cancelled;
    mutable QAtomicInt m_progress;
};

} // namespace DeepinDoctor

#endif // EXAMPLE_MODULE_H
