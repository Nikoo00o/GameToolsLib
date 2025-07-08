#ifndef EXPORTS_H
#define EXPORTS_H

#ifdef __cplusplus

#ifdef WIN32
   #define EXPORT __declspec(dllexport)
#else
   #define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif // #ifdef WIN32

#else

#ifdef WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif // #ifdef WIN32

#endif  // #ifdef __cplusplus


#endif //EXPORTS_H