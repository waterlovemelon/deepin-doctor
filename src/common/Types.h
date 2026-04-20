#ifndef DEEPIN_DOCTOR_TYPES_H
#define DEEPIN_DOCTOR_TYPES_H

#include <QString>
#include <QJsonObject>
#include <QList>

namespace DeepinDoctor {

struct Issue {
    enum Level {
        Error,
        Warning,
        Info
    };

    Level level;
    QString title;
    QString description;
    QString solution;

    QJsonObject toJson() const {
        return QJsonObject{
            {"level", level == Error ? "error" : level == Warning ? "warning" : "info"},
            {"title", title},
            {"description", description},
            {"solution", solution}
        };
    }

    static Issue fromJson(const QJsonObject& json) {
        Issue issue;
        QString levelStr = json["level"].toString();
        issue.level = levelStr == "error" ? Error : levelStr == "warning" ? Warning : Info;
        issue.title = json["title"].toString();
        issue.description = json["description"].toString();
        issue.solution = json["solution"].toString();
        return issue;
    }
};

struct ModuleInfo {
    QString name;
    QString description;
    QString version;

    QJsonObject toJson() const {
        return QJsonObject{
            {"name", name},
            {"description", description},
            {"version", version}
        };
    }
};

} // namespace DeepinDoctor

#endif // DEEPIN_DOCTOR_TYPES_H
